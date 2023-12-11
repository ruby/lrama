module Lrama
  class Grammar
    class ParameterizingRuleResolver
      def initialize
        @parameterizing_rule_builders = []
      end

      def add_parameterizing_rule_builder(builder)
        @parameterizing_rule_builders << builder
      end

      def defined?(name)
        @parameterizing_rule_builders.any? { |builder| builder.name == name }
      end

      def build_rules(token, rule_counter, lhs_tag, line)
        builder = @parameterizing_rule_builders.select { |b| b.name == token.s_value }.last
        raise "Unknown parameterizing rule #{token.s_value} at line #{token.line}" unless builder

        builder.build_rules(token, rule_counter, lhs_tag, line)
      end
    end
  end
end
