require 'lrama/grammar/parameterizing_rules/builder'

module Lrama
  class Grammar
    class RuleBuilder
      attr_accessor :lhs, :lhs_tag, :line
      attr_reader :rhs, :user_code, :precedence_sym

      def initialize(rule_counter, midrule_action_counter, position_in_original_rule_rhs = nil, skip_preprocess_references: false)
        @rule_counter = rule_counter
        @midrule_action_counter = midrule_action_counter
        @position_in_original_rule_rhs = position_in_original_rule_rhs
        @skip_preprocess_references = skip_preprocess_references

        @lhs = nil
        @rhs = []
        @lhs_tag = nil
        @user_code = nil
        @precedence_sym = nil
        @line = nil
        @rule_builders_for_derived_rules = []
      end

      def add_rhs(rhs)
        if !@line
          @line = rhs.line
        end

        flush_user_code

        @rhs << rhs
      end

      def user_code=(user_code)
        if !@line
          @line = user_code.line
        end

        flush_user_code

        @user_code = user_code
      end

      def precedence_sym=(precedence_sym)
        flush_user_code

        @precedence_sym = precedence_sym
      end

      def complete_input
        freeze_rhs
      end

      def setup_rules(parameterizing_resolver)
        preprocess_references unless @skip_preprocess_references
        process_rhs(parameterizing_resolver)
        build_rules
      end

      def parameterizing_rules
        @parameterizing_rules
      end

      def midrule_action_rules
        @midrule_action_rules
      end

      def rules
        @rules
      end

      private

      def freeze_rhs
        @rhs.freeze
      end

      def preprocess_references
        numberize_references
      end

      def build_rules
        tokens = @replaced_rhs

        rule = Rule.new(
          id: @rule_counter.increment, _lhs: lhs, _rhs: tokens, token_code: user_code,
          position_in_original_rule_rhs: @position_in_original_rule_rhs, precedence_sym: precedence_sym, lineno: line
        )
        @rules = [rule]
        @midrule_action_rules = @rule_builders_for_derived_rules.map do |rule_builder|
          rule_builder.rules
        end.flatten
        @midrule_action_rules.each do |r|
          r.original_rule = rule
        end
      end

      # rhs is a mixture of variety type of tokens like `Ident`, `InstantiateRule`, `UserCode` and so on.
      # `#process_rhs` replaces some kind of tokens to `Ident` so that all `@replaced_rhs` are `Ident` or `Char`.
      def process_rhs(parameterizing_resolver)
        return if @replaced_rhs

        @replaced_rhs = []
        @parameterizing_rules = []

        rhs.each_with_index do |token, i|
          case token
          when Lrama::Lexer::Token::Char
            @replaced_rhs << token
          when Lrama::Lexer::Token::Ident
            @replaced_rhs << token
          when Lrama::Lexer::Token::InstantiateRule
            if parameterizing_resolver.defined?(token.s_value)
              parameterizing = parameterizing_resolver.build_rules(token, @rule_counter, @lhs_tag, line)
              @parameterizing_rules = @parameterizing_rules + parameterizing.map(&:rules).flatten
              @replaced_rhs = @replaced_rhs + parameterizing.map(&:token).flatten.uniq
            else
              # TODO: Delete when the standard library will defined as a grammar file.
              parameterizing = ParameterizingRules::Builder.new(token, @rule_counter, @lhs_tag, user_code, precedence_sym, line)
              @parameterizing_rules = @parameterizing_rules + parameterizing.build
              @replaced_rhs << parameterizing.build_token
            end
          when Lrama::Lexer::Token::ParserStatePop
            process_parser_state_token(token, "parser_state_pop_", "YYPOP_STATE_#{token.s_value.upcase}();", i, parameterizing_resolver)
          when Lrama::Lexer::Token::ParserStatePush
            process_parser_state_token(token, "parser_state_push_", "YYPUSH_STATE_#{token.s_value.upcase}(#{token.state.s_value});", i, parameterizing_resolver)
          when Lrama::Lexer::Token::ParserStateSet
            process_parser_state_token(token, "parser_state_set_", "YYSET_STATE_#{token.s_value.upcase}(#{token.state.s_value});", i, parameterizing_resolver)
          when Lrama::Lexer::Token::UserCode
            prefix = token.referred ? "@" : "$@"
            new_token = Lrama::Lexer::Token::Ident.new(s_value: prefix + @midrule_action_counter.increment.to_s)
            @replaced_rhs << new_token

            rule_builder = RuleBuilder.new(@rule_counter, @midrule_action_counter, i, skip_preprocess_references: true)
            rule_builder.lhs = new_token
            rule_builder.user_code = token
            rule_builder.complete_input
            rule_builder.setup_rules(parameterizing_resolver)

            @rule_builders_for_derived_rules << rule_builder
          else
            raise "Unexpected token. #{token}"
          end
        end
      end

      def process_parser_state_token(token, prefix, code, position_in_original_rule_rhs, parameterizing_resolver)
        new_token = Lrama::Lexer::Token::Ident.new(s_value: prefix + token.s_value + @midrule_action_counter.increment.to_s)
        user_code = Lrama::Lexer::Token::UserCode.new(s_value: code, location: token.location)

        @replaced_rhs << new_token
        rule_builder = RuleBuilder.new(@rule_counter, @midrule_action_counter, position_in_original_rule_rhs, skip_preprocess_references: true)
        rule_builder.lhs = new_token
        rule_builder.user_code = user_code
        rule_builder.complete_input
        rule_builder.setup_rules(parameterizing_resolver)

        @rule_builders_for_derived_rules << rule_builder
      end

      def numberize_references
        # Bison n'th component is 1-origin
        (rhs + [user_code]).compact.each.with_index(1) do |token, i|
          next unless token.is_a?(Lrama::Lexer::Token::UserCode)

          token.references.each do |ref|
            # Derive number reference index from named reference
            ref_name = ref.name
            if ref_name && ref_name != '$'
              if lhs.referred_by?(ref_name)
                ref.name = '$'
              else
                candidates = referable_tokens.each_with_index.select {|token, i| token.referred_by?(ref_name) }

                raise "Referring symbol `#{ref_name}` is duplicated. #{token}" if candidates.size >= 2
                raise "Referring symbol `#{ref_name}` is not found. #{token}" unless referring_symbol = candidates.first

                ref.number = referring_symbol[1] + 1
              end
            end

            if ref.number
              # Remapping number reference index to include non referable tokens
              # TODO: Is it better to separate "number" of reference from actual "index" (Grammar::Reference)?
              ref.index = number_to_index[ref.number]

              if !ref.index
                raise "Can not refer to not exist component. $#{ref.number}"
              end
            end

            # TODO: Need to check index of @ too?
            next if ref.type == :at
            if ref.index
              # TODO: Prohibit $0 even so Bison allows it?
              # See: https://www.gnu.org/software/bison/manual/html_node/Actions.html
              raise "Can not refer following component. #{ref.index} >= #{i}. #{token}" if ref.index >= i
              rhs[ref.index - 1].referred = true
            end
          end
        end
      end

      def referable_token?(token)
        case token
        when Lrama::Lexer::Token::ParserStatePop
          false
        when Lrama::Lexer::Token::ParserStatePush
          false
        when Lrama::Lexer::Token::ParserStateSet
          false
        else
          true
        end
      end

      def referable_tokens
        rhs.select do |token|
          referable_token?(token)
        end
      end

      def number_to_index
        return @number_to_index if @number_to_index

        @number_to_index = [0]

        rhs.each.with_index(1) do |token, i|
          if referable_token?(token)
            @number_to_index << i
          end
        end

        @number_to_index
      end

      def flush_user_code
        if c = @user_code
          @rhs << c
          @user_code = nil
        end
      end
    end
  end
end
