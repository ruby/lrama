# rbs_inline: enabled
# frozen_string_literal: true

require_relative "../node"
require_relative "../../lexer"

module Lrama
  class Grammar
    class Inline
      class Action
        # Keep a whole YYSTYPE copy together when a later expansion replaces its source.
        class GeneratedCode < Lexer::Token::UserCode
          private

          # @rbs (StringScanner scanner) -> Reference?
          def scan_reference(scanner)
            if (text = scanner.scan(/\(yyvsp\[1 \+ \$:([0-9]+)\]\)/))
              index = scanner[1].to_i
              Reference.new(type: :stack_value, index: index, first_column: scanner.charpos - text.length, last_column: scanner.charpos)
            else
              super
            end
          end
        end

        class ExpandedAction < Node::RuleRhs::Action
          attr_reader :prefixes #: Array[[Integer, Lexer::Token::UserCode]]
          attr_reader :body #: String
          attr_reader :initial_value #: String?
          attr_reader :default_location #: Lexer::Token::UserCode?

          # @rbs (Array[[Integer, Lexer::Token::UserCode]] prefixes, String body, Node::RuleRhs::Action origin, String? initial_value, Lexer::Token::UserCode? default_location) -> void
          def initialize(prefixes, body, origin, initial_value, default_location)
            @prefixes = prefixes
            @body = body
            @initial_value = initial_value
            @default_location = default_location
            text = prefixes.map { |_last, code| code.s_value }.join
            text << " yyval = #{initial_value}; " if initial_value
            text << default_location.s_value if default_location
            text << body
            code = Lexer::Token::UserCode.new(s_value: text, location: origin.code.location)
            super(code: code, alias_name: origin.alias_name, tag: origin.tag, location: origin.location)
          end
        end

        # @rbs (RuleBuilder source, Parameterized::Rule rule, Parameterized::Rhs rhs, Integer index, Lexer::Token::Tag? tag) -> void
        def initialize(source, rule, rhs, index, tag)
          @source = source
          @rhs = rhs
          @index = index
          @size = rhs.symbols.length
          @tag = tag
          @rule = rule
          @value = "yyinline_#{source.parameterized_resolver.inline_counter.increment}"
          @location = "#{@value}_loc"
          inner = rhs.action
          code = source.positional_action_code(inner.code, symbols: rhs.symbols, lhs_name: rule.name, lhs_alias: nil) if inner
          refs = code&.references.to_a
          @binds_value = refs.any? { |ref| ref.type == :dollar && ref.name == "$" }
          @uses_location = refs.any? { |ref| ref.type == :at && ref.name == "$" }
          @fragment = !!inner && !@binds_value && !inner.code.ends_with_statement?
          nested = rhs.symbols.any? { |symbol| source.parameterized_resolver.find_inline(symbol) }
          @logical_locations = @uses_location || (!@fragment && source.parameterized_resolver.locations && (@size != 1 || inner || nested))
          @uses_location ||= @logical_locations
          # A midrule action runs in a separate reduction, so its inputs must live on the parser stack.
          following_actions = source.rhs.drop(index + 1).grep(Node::RuleRhs::Action) #: Array[Node::RuleRhs::Action]
          @on_stack = false
          unless following_actions.empty?
            locations = (following_actions + [source.action]).compact.any? { |action| action.code.references.any? { |ref| ref.type == :at } }
            @on_stack = (!!inner && !@fragment) || @logical_locations || (@size != 1 && locations)
            @uses_location ||= @on_stack && (locations || @logical_locations)
          end
          @inline_code = inner_code(code) if code
        end

        # @rbs () -> Node::RuleRhs::Action?
        def stack_action
          return unless @on_stack

          code = action_prefix
          location = @rhs.action&.location || @source.rhs.fetch(@index).location
          Node::RuleRhs::Action.new(code: Lexer::Token::UserCode.new(s_value: code, location: location), tag: @tag, location: location)
        end

        # @rbs (Node::RuleRhs::Action action, Integer position) -> Node::RuleRhs::Action
        def rewrite_midrule(action, position)
          code = @source.positional_action_code(action.code, position: position)
          Node::RuleRhs::Action.new(code: rewrite_outer(code), alias_name: action.alias_name, tag: action.tag, location: action.location)
        end

        # @rbs () -> Node::RuleRhs::Action?
        def expand
          outer = @source.action
          inner = @rhs.action
          origin = outer || inner
          unless origin
            return unless @logical_locations

            location = @source.rhs.fetch(@index).location
            origin = Node::RuleRhs::Action.new(code: Lexer::Token::UserCode.new(s_value: "", location: location), location: location)
          end

          # Previous siblings run before this action, and enclosing actions run after it.
          prefixes = outer.is_a?(ExpandedAction) ? outer.prefixes : [] #: Array[[Integer, Lexer::Token::UserCode]]
          before, after = prefixes.partition { |last, _code| last <= @index }
          after = after.map do |last, code|
            [last + offset, rewrite_outer(code)] #: [Integer, Lexer::Token::UserCode]
          end
          body = outer_body(outer)
          initial_value = outer.initial_value if outer.is_a?(ExpandedAction)
          if initial_value
            code = GeneratedCode.new(s_value: initial_value, location: origin.code.location)
            initial_value = rewrite_outer(code).s_value
          elsif @index == 0 && @binds_value
            initial_value = @on_stack ? stack_value(@size + 1) : @value
          end
          default_location = outer.default_location if outer.is_a?(ExpandedAction)
          if !default_location && @logical_locations
            default_location = Lexer::Token::UserCode.new(s_value: location_default("@$", 0, @source.rhs.length), location: origin.code.location)
          end
          default_location = rewrite_outer(default_location) if default_location
          prefix = @on_stack ? "" : action_prefix
          unless prefix.empty?
            before << [@index + @size, Lexer::Token::UserCode.new(s_value: prefix, location: origin.code.location)]
          end
          before.concat(after)
          return unless outer || !before.empty? || initial_value || default_location

          ExpandedAction.new(before, body, origin, initial_value, default_location)
        end

        private

        # @rbs (Lexer::Token::UserCode code) -> String
        def inner_code(code)
          replace_references(code) do |ref|
            if ref.name == "$" && ref.type == :dollar
              value(ref)
            elsif ref.name == "$" && ref.type == :at
              @fragment && @on_stack ? "@#{@index + @size + 1}" : location_target
            elsif ref.index
              ref.spelling(ref.index + @index)
            end
          end
        end

        # @rbs () -> String
        def action_prefix
          prefix = +""
          if @uses_location
            prefix << " YYLTYPE #{@location};" unless @on_stack
            prefix << location_default(location_target, @index, @size)
          end
          if @binds_value
            if @size > 0
              target = @on_stack ? "yyval" : "YYSTYPE #{@value}"
              prefix << " #{target} = #{stack_value(@index + 1)};"
            elsif !@on_stack
              prefix << " YYSTYPE #{@value};"
            end
          end
          prefix << " { #{@inline_code} } " if @inline_code && !@fragment
          prefix
        end

        # @rbs (Node::RuleRhs::Action? outer) -> String
        def outer_body(outer)
          if outer
            code =
              if outer.is_a?(ExpandedAction)
                Lexer::Token::UserCode.new(s_value: outer.body, location: outer.code.location)
              else
                @source.positional_action_code(outer.code)
              end
            rewrite_outer(code).s_value
          else
            ""
          end
        end

        # @rbs () -> Integer
        def offset
          @on_stack ? @size : @size - 1
        end

        # @rbs (Lexer::Token::UserCode code) -> Lexer::Token::UserCode
        def rewrite_outer(code)
          if code.s_value.include?("(yyvsp[1 + $:")
            code = GeneratedCode.new(s_value: code.s_value, location: code.location)
          end
          text = replace_references(code) do |ref|
            next unless ref.index && ref.index > @index

            if ref.type == :stack_value
              if ref.index == @index + 1
                @binds_value ? (@on_stack ? stack_value(ref.index + offset) : "(#{@value})") : stack_value(ref.index)
              else
                stack_value(ref.index + offset)
              end
            elsif ref.index == @index + 1 && ref.type == :dollar
              if @binds_value
                @on_stack ? ref.spelling(ref.index + offset) : value(ref)
              else
                @fragment ? @inline_code : ref.spelling(ref.index, ref.ex_tag || @tag)
              end
            elsif ref.index == @index + 1 && ref.type == :at && (@size != 1 || @uses_location)
              @uses_location = true
              @on_stack ? ref.spelling(ref.index + offset) : @location
            else
              ref.spelling(ref.index + offset)
            end
          end
          Lexer::Token::UserCode.new(s_value: text, location: code.location)
        end

        # @rbs (Lexer::Token::UserCode code) { (Reference) -> String? } -> String
        def replace_references(code)
          text = code.s_value.dup
          code.references.reverse_each do |ref|
            replacement = yield ref
            text[ref.first_column...ref.last_column] = replacement if replacement
          end
          text
        end

        # @rbs (Integer position) -> String
        def stack_value(position)
          "(yyvsp[1 + $:#{position}])"
        end

        # @rbs (String target, Integer index, Integer size) -> String
        def location_default(target, index, size)
          positions = (index..(index + size)).map { |i| "@#{i}" }.join(", ")
          " { YYLTYPE rhs[] = { #{positions} }; YYLLOC_DEFAULT(#{target}, rhs, #{size}); } "
        end

        # @rbs () -> String
        def location_target
          @on_stack ? "@$" : @location
        end

        # @rbs (Reference ref) -> String
        def value(ref)
          tag = ref.ex_tag || @tag
          target = @on_stack ? "yyval" : @value
          return "#{target}.#{tag.member}" if tag.is_a?(Lexer::Token::Tag)
          if @source.parameterized_resolver.union_defined
            raise "Tag is not specified for inline rule '#{@rule.name}'"
          end
          target
        end
      end
    end
  end
end
