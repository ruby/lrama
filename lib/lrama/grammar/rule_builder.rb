# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    class RuleBuilder
      # TODO: rbs-inline 0.11.0 doesn't support instance variables.
      #       Move these type declarations above instance variable definitions, once it's supported.
      #       see: https://github.com/soutaro/rbs-inline/pull/149
      #
      # @rbs!
      #   @position_in_original_rule_rhs: Integer?
      #   @skip_preprocess_references: bool
      #   @trailing_precedence: bool
      #   @rules: Array[Rule]
      #   @rule_builders_for_parameterized: Array[RuleBuilder]
      #   @rule_builders_for_derived_rules: Array[RuleBuilder]
      #   @parameterized_rules: Array[Rule]
      #   @midrule_action_rules: Array[Rule]
      #   @replaced_rhs: Array[Grammar::Symbol::Id]?
      #   @replaced_rhs_locations: Array[Lexer::Location?]?

      attr_accessor :lhs #: Grammar::Symbol::Id?
      attr_accessor :lhs_location #: Lexer::Location?
      attr_accessor :lhs_alias_name #: String?
      attr_accessor :line #: Integer?
      attr_reader :rule_counter #: Counter
      attr_reader :midrule_action_counter #: Counter
      attr_reader :parameterized_resolver #: Grammar::Parameterized::Resolver
      attr_reader :lhs_tag #: Lexer::Token::Tag?
      attr_reader :rhs #: Array[Node::RuleRhs::rhs]
      attr_reader :action #: Node::RuleRhs::Action?
      attr_reader :precedence_sym #: Grammar::Symbol?

      # @rbs (Counter rule_counter, Counter midrule_action_counter, Grammar::Parameterized::Resolver parameterized_resolver, ?Integer position_in_original_rule_rhs, ?lhs_tag: Lexer::Token::Tag?, ?skip_preprocess_references: bool) -> void
      def initialize(rule_counter, midrule_action_counter, parameterized_resolver, position_in_original_rule_rhs = nil, lhs_tag: nil, skip_preprocess_references: false)
        @rule_counter = rule_counter
        @midrule_action_counter = midrule_action_counter
        @parameterized_resolver = parameterized_resolver
        @position_in_original_rule_rhs = position_in_original_rule_rhs
        @skip_preprocess_references = skip_preprocess_references
        @trailing_precedence = false

        @lhs = nil
        @lhs_location = nil
        @lhs_alias_name = nil
        @lhs_tag = lhs_tag
        @rhs = []
        @action = nil
        @precedence_sym = nil
        @line = nil
        @rules = []
        @rule_builders_for_parameterized = []
        @rule_builders_for_derived_rules = []
        @parameterized_rules = []
        @midrule_action_rules = []
      end

      # @rbs (Node::RuleRhs::rhs rhs) -> void
      def add_rhs(rhs)
        @line ||= rhs.location.first_line

        @rhs << rhs
        @trailing_precedence = false
      end

      # @rbs (Grammar::Symbol? precedence_sym) -> void
      def precedence_sym=(precedence_sym)
        @precedence_sym = precedence_sym
        @trailing_precedence = !precedence_sym.nil?
      end

      # @rbs () -> void
      def complete_input
        if (action = final_action)
          @action = action
          @rhs.pop
        end

        freeze_rhs
      end

      # @rbs () -> void
      def setup_rules
        preprocess_references unless @skip_preprocess_references
        process_rhs
        resolve_inline_rules
        build_rules
      end

      # @rbs () -> Array[Grammar::Rule]
      def rules
        @parameterized_rules + @midrule_action_rules + @rules
      end

      # @rbs () -> bool
      def has_inline_rules?
        rhs.any? do |node|
          (node.is_a?(Node::RuleRhs::Symbol) || node.is_a?(Node::RuleRhs::InstantiateRule)) &&
            @parameterized_resolver.find_inline(node)
        end
      end

      # Resolve names while their declaring rule and original source offsets are available.
      # @rbs (Lexer::Token::UserCode code, ?symbols: Array[Node::RuleRhs::rhs], ?lhs_name: String?, ?lhs_alias: String?, ?position: Integer) -> Lexer::Token::UserCode
      def positional_action_code(code, symbols: rhs, lhs_name: lhs&.name, lhs_alias: lhs_alias_name, position: symbols.length + 1)
        resolve_action_references(code, symbols, lhs_name, lhs_alias, position)
        return code unless code.references.any?(&:name)

        text = code.s_value.dup
        code.references.reverse_each do |ref|
          next unless ref.name

          text[ref.first_column...ref.last_column] = ref.spelling
        end
        Lexer::Token::UserCode.new(s_value: text, location: code.location)
      end

      private

      # @rbs () -> void
      def freeze_rhs
        @rhs.freeze
      end

      # @rbs () -> Node::RuleRhs::Action?
      def final_action
        return if @trailing_precedence

        action = @rhs.last
        action if action.is_a?(Node::RuleRhs::Action)
      end

      # @rbs () -> void
      def preprocess_references
        numberize_references
      end

      # @rbs () -> void
      def build_rules
        symbols = @replaced_rhs #: Array[Grammar::Symbol::Id]
        locations = @replaced_rhs_locations #: Array[Lexer::Location?]
        return if has_inline_rules?

        rule = Rule.new(
          id: @rule_counter.increment,
          _lhs: lhs,
          _rhs: symbols,
          _lhs_location: lhs_location, _rhs_locations: locations,
          lhs_tag: lhs_tag, token_code: action&.code,
          position_in_original_rule_rhs: @position_in_original_rule_rhs, precedence_sym: precedence_sym, lineno: line
        )
        @rules = [rule]
        @parameterized_rules = @rule_builders_for_parameterized.map do |rule_builder|
          rule_builder.rules
        end.flatten
        @midrule_action_rules = @rule_builders_for_derived_rules.map do |rule_builder|
          rule_builder.rules
        end.flatten
        @midrule_action_rules.each do |r|
          r.original_rule = rule
        end
      end

      # `#process_rhs` lowers RHS nodes to symbol IDs.
      #
      # @rbs () -> void
      def process_rhs
        return if @replaced_rhs

        replaced_rhs = [] #: Array[Grammar::Symbol::Id]
        replaced_rhs_locations = [] #: Array[Lexer::Location?]

        rhs.each_with_index do |node, i|
          case node
          when Node::RuleRhs::Symbol
            token = node.token
            replaced_rhs << Grammar::Symbol::Id.from_token(token)
            replaced_rhs_locations << token.location
          when Node::RuleRhs::InstantiateRule
            parameterized_rule = @parameterized_resolver.find_rule(node)
            raise "Unexpected node. #{node}" unless parameterized_rule

            bindings = Binding.new(parameterized_rule.parameters, node.args)
            lhs_s_value = bindings.concatenated_args_str(node)
            if (created_lhs = @parameterized_resolver.created_lhs(lhs_s_value))
              replaced_rhs << created_lhs
            else
              lhs_id = Grammar::Symbol::Id.new(name: lhs_s_value, kind: :ident)
              replaced_rhs << lhs_id
              @parameterized_resolver.created_lhs_list << lhs_id
              parameterized_rule.rhs.each do |r|
                rule_builder = RuleBuilder.new(@rule_counter, @midrule_action_counter, @parameterized_resolver, lhs_tag: node.lhs_tag || parameterized_rule.tag)
                rule_builder.lhs = lhs_id
                rule_builder.lhs_location = node.location
                r.symbols.each { |sym| rule_builder.add_rhs(bindings.resolve_symbol(sym)) }
                rule_builder.line = line
                rule_builder.precedence_sym = r.precedence_sym
                if (action = r.resolve_action(bindings))
                  rule_builder.add_rhs(action)
                end
                rule_builder.complete_input
                rule_builder.setup_rules
                @rule_builders_for_parameterized << rule_builder
              end
            end
            replaced_rhs_locations << node.location
          when Node::RuleRhs::Action
            prefix = node.code.referred ? "@" : "$@"
            tag = node.tag || lhs_tag
            lhs_id = Grammar::Symbol::Id.new(name: prefix + @midrule_action_counter.increment.to_s, kind: :ident)
            replaced_rhs << lhs_id
            replaced_rhs_locations << nil

            rule_builder = RuleBuilder.new(@rule_counter, @midrule_action_counter, @parameterized_resolver, i, lhs_tag: tag, skip_preprocess_references: true)
            rule_builder.lhs = lhs_id
            rule_builder.add_rhs(node)
            rule_builder.complete_input
            rule_builder.setup_rules

            @rule_builders_for_derived_rules << rule_builder
          when Node::RuleRhs::Empty
            # Noop
          else
            raise "Unexpected node. #{node}"
          end
        end

        @replaced_rhs = replaced_rhs
        @replaced_rhs_locations = replaced_rhs_locations
      end

      # @rbs () -> void
      def resolve_inline_rules
        while @rule_builders_for_parameterized.any?(&:has_inline_rules?) do
          @rule_builders_for_parameterized = @rule_builders_for_parameterized.flat_map do |rule_builder|
            if rule_builder.has_inline_rules?
              inlined_builders = Inline::Resolver.new(rule_builder).resolve
              inlined_builders.each { |builder| builder.setup_rules }
              inlined_builders
            else
              rule_builder
            end
          end
        end
      end

      # @rbs () -> void
      def numberize_references
        (rhs + [action]).compact.each.with_index(1) do |node, position|
          next unless node.is_a?(Node::RuleRhs::Action)

          resolve_action_references(node.code, rhs, lhs&.name, lhs_alias_name, position)
        end
      end

      # @rbs (Lexer::Token::UserCode token, Array[Node::RuleRhs::rhs] symbols, String? lhs_name, String? lhs_alias, Integer position) -> void
      def resolve_action_references(token, symbols, lhs_name, lhs_alias, position)
        token.references.each do |ref|
          name = ref.name
          if name && name != '$'
            candidates = [] #: Array[Integer]
            candidates << 0 if name == lhs_name || name == lhs_alias
            symbols.each_with_index do |node, index|
              candidates << index + 1 if rhs_node_referred_by?(node, name)
            end
            token.invalid_ref(ref, "Referring symbol `#{name}` is duplicated.") if candidates.size > 1
            target = candidates.first
            token.invalid_ref(ref, "Referring symbol `#{name}` is not found.") unless target
            if target == 0
              ref.name = '$'
            else
              ref.number = target
            end
          end

          ref.index = ref.number if ref.number
          next if ref.type == :at || !ref.index

          token.invalid_ref(ref, "Can not refer following component. #{ref.index} >= #{position}.") if ref.index >= position
          mark_rhs_node_referred(symbols[ref.index - 1])
        end
      end

      # @rbs (Node::RuleRhs::rhs node, String name) -> bool
      def rhs_node_referred_by?(node, name)
        case node
        when Node::RuleRhs::Symbol, Node::RuleRhs::InstantiateRule
          node.name == name || node.alias_name == name
        when Node::RuleRhs::Action
          node.code.s_value == name || node.alias_name == name
        else
          false
        end
      end

      # @rbs (Node::RuleRhs::rhs node) -> void
      def mark_rhs_node_referred(node)
        if node.is_a?(Node::RuleRhs::Action)
          node.code.referred = true
        end
      end
    end
  end
end
