# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    class Inline
      # Validates inline rules according to Menhir specification.
      # Detects:
      # - Direct recursion (inline rule references itself)
      # - Mutual recursion (inline rules reference each other in a cycle)
      # - Start symbol declared as inline
      class Validator
        class RecursiveInlineError < StandardError; end
        class StartSymbolInlineError < StandardError; end

        # @rbs (Lrama::Grammar::Parameterized::Resolver parameterized_resolver, Lexer::Token::Base? start_nterm) -> void
        def initialize(parameterized_resolver, start_nterm = nil)
          @parameterized_resolver = parameterized_resolver
          @start_nterm = start_nterm
        end

        # @rbs () -> void
        def validate!
          inline_rules = collect_inline_rules
          return if inline_rules.empty?

          validate_no_start_symbol_inline(inline_rules)
          validate_no_recursion(inline_rules)
        end

        private

        # @rbs () -> Array[Lrama::Grammar::Parameterized::Rule]
        def collect_inline_rules
          @parameterized_resolver.rules.select(&:inline?)
        end

        # @rbs (Array[Lrama::Grammar::Parameterized::Rule] inline_rules) -> void
        def validate_no_start_symbol_inline(inline_rules)
          return unless @start_nterm

          start_symbol_name = @start_nterm.s_value
          inline_names = inline_rules.map(&:name)

          if inline_names.include?(start_symbol_name)
            raise StartSymbolInlineError, "Start symbol '#{start_symbol_name}' cannot be declared as inline."
          end
        end

        # @rbs (Array[Lrama::Grammar::Parameterized::Rule] inline_rules) -> void
        def validate_no_recursion(inline_rules)
          inline_names = inline_rules.map(&:name).to_set

          inline_rules.each do |rule|
            check_recursion(rule, inline_names, Set.new)
          end
        end

        # @rbs (Lrama::Grammar::Parameterized::Rule rule, Set[String] inline_names, Set[String] visited) -> void
        def check_recursion(rule, inline_names, visited)
          if visited.include?(rule.name)
            raise RecursiveInlineError, "Recursive inline definition detected: #{visited.to_a.join(' -> ')} -> #{rule.name}. Inline rules cannot reference themselves directly or indirectly."
          end

          new_visited = visited + [rule.name]

          rule.rhs.each do |rhs|
            rhs.symbols.each do |symbol|
              symbol_name = symbol.s_value

              if inline_names.include?(symbol_name)
                referenced_rule = @parameterized_resolver.rules.find { |r| r.name == symbol_name && r.inline? }
                if referenced_rule
                  check_recursion(referenced_rule, inline_names, new_visited)
                end
              end
            end
          end
        end
      end
    end
  end
end
