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
        class RecursiveInlineError < RuntimeError; end
        class StartSymbolInlineError < StandardError; end

        # @rbs (Lrama::Grammar::Parameterized::Resolver parameterized_resolver, Lexer::Token::Base? start_nterm) -> void
        def initialize(parameterized_resolver, start_nterm = nil)
          @parameterized_resolver = parameterized_resolver
          @start_nterm = start_nterm
        end

        # @rbs () -> void
        def validate!
          inline_rules = @parameterized_resolver.rules.select(&:inline?)
          validate_no_start_symbol_inline(inline_rules)
          visiting = {} #: Hash[Parameterized::Rule, bool]
          visited = {} #: Hash[Parameterized::Rule, bool]
          inline_rules.each { |rule| check_recursion(rule, visiting, visited) }
        end

        private

        # @rbs (Array[Lrama::Grammar::Parameterized::Rule] inline_rules) -> void
        def validate_no_start_symbol_inline(inline_rules)
          return unless @start_nterm

          start_symbol_name = @start_nterm.s_value
          if inline_rules.any? { |rule| rule.name == start_symbol_name && rule.parameters.empty? }
            message = "Start symbol '#{start_symbol_name}' cannot be declared as inline."
            raise StartSymbolInlineError, @start_nterm.location.generate_error_message(message)
          end
        end

        # @rbs (Parameterized::Rule rule, Hash[Parameterized::Rule, bool] visiting, Hash[Parameterized::Rule, bool] visited) -> void
        def check_recursion(rule, visiting, visited)
          return if visited[rule]

          visiting[rule] = true
          rule.rhs.each do |rhs|
            rhs.symbols.each do |symbol|
              next if rule.parameters.any? { |parameter| parameter.s_value == symbol.name }

              referenced_rule = @parameterized_resolver.find_inline(symbol)
              next unless referenced_rule
              if visiting[referenced_rule]
                path = visiting.keys.map(&:name) + [referenced_rule.name]
                message = "Recursive inline definition detected: #{path.join(' -> ')}."
                raise RecursiveInlineError, symbol.location.generate_error_message(message)
              end
              check_recursion(referenced_rule, visiting, visited)
            end
          end
          visiting.delete(rule)
          visited[rule] = true
        end
      end
    end
  end
end
