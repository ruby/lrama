module Lrama
  class Grammar
    class ParameterizingRuleRhsBuilder
      attr_accessor :symbols, :user_code, :precedence_sym

      def initialize
        @symbols = []
        @user_code = nil
        @precedence_sym = nil
      end

      def build_rules(token, actual_args, parameters, rule_counter, lhs, lhs_tag, line, rule_builders)
        nested_rules = build_nested_rules(actual_args, parameters, rule_counter, lhs_tag, line, rule_builders)
        rhs = rhs(token, actual_args, parameters, nested_rules.last)
        rule = Rule.new(id: rule_counter.increment, _lhs: lhs, _rhs: rhs, lhs_tag: lhs_tag, token_code: user_code, precedence_sym: precedence_sym, lineno: line)
        ParameterizingRule.new(rules: nested_rules.map(&:rules) + [rule], token: lhs)
      end

      private

      def build_nested_rules(actual_args, parameters, rule_counter, lhs_tag, line, rule_builders)
        symbols.each_with_index.map do |sym, i|
          next unless sym.is_a?(Lexer::Token::InstantiateRule)

          builder = rule_builders.select { |builder| builder.name == sym.s_value }.last
          raise "Unknown parameterizing rule #{sym.s_value} at line #{sym.line}" unless builder

          args = symbols[i].args.actual_values(actual_args, parameters)
          builder.build_rules(sym, args, rule_counter, lhs_tag, line, rule_builders)
        end.flatten.compact
      end

      def rhs(token, actual_args, parameters, nested_rule)
        symbols.map do |sym|
          if sym.is_a?(Lexer::Token::InstantiateRule)
            raise "`build_nested_rules` must be called before `rhs`" unless nested_rule

            sym.args.replace_token(parameters, sym, nested_rule.token)
          else
            idx = parameters.index { |parameter| parameter.s_value == sym.s_value }
            idx.nil? ? sym : actual_args[idx]
          end
        end.flatten
      end
    end
  end
end
