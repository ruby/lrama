# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    class Parameterized
      class Resolver
        attr_reader :inline_counter #: Counter
        attr_accessor :locations #: bool
        attr_accessor :union_defined #: bool
        attr_accessor :rules #: Array[Rule]
        attr_accessor :created_lhs_list #: Array[Grammar::Symbol::Id]

        # @rbs () -> void
        def initialize
          @inline_counter = Counter.new(1)
          @locations = false
          @union_defined = false
          @rules = []
          @created_lhs_list = []
        end

        # @rbs (Rule rule) -> Array[Rule]
        def add_rule(rule)
          @rules << rule
        end

        # @rbs (Node::RuleRhs::InstantiateRule instantiate_rule) -> Rule?
        def find_rule(instantiate_rule)
          select_rules(@rules, instantiate_rule).last
        end

        # @rbs (Node::RuleRhs::value node) -> Rule?
        def find_inline(node)
          arity = node.is_a?(Node::RuleRhs::InstantiateRule) ? node.args.length : 0
          @rules.reverse_each.find { |rule| rule.inline? && rule.name == node.name && rule.required_parameters_count == arity }
        end

        # @rbs (String lhs_s_value) -> Grammar::Symbol::Id?
        def created_lhs(lhs_s_value)
          @created_lhs_list.reverse.find { |created_lhs| created_lhs.name == lhs_s_value }
        end

        # @rbs () -> Array[Rule]
        def redefined_rules
          @rules.select { |rule| @rules.count { |r| r.name == rule.name && r.required_parameters_count == rule.required_parameters_count } > 1 }
        end

        private

        # @rbs (Array[Rule] rules, Node::RuleRhs::InstantiateRule instantiate_rule) -> Array[Rule]
        def select_rules(rules, instantiate_rule)
          rules = reject_inline_rules(rules)
          rules = select_rules_by_name(rules, instantiate_rule.name)
          rules = rules.select { |rule| rule.required_parameters_count == instantiate_rule.args.count }
          if rules.empty?
            raise "Invalid number of arguments. `#{instantiate_rule.name}`"
          else
            rules
          end
        end

        # @rbs (Array[Rule] rules) -> Array[Rule]
        def reject_inline_rules(rules)
          rules.reject(&:inline?)
        end

        # @rbs (Array[Rule] rules, String rule_name) -> Array[Rule]
        def select_rules_by_name(rules, rule_name)
          rules = rules.select { |rule| rule.name == rule_name }
          if rules.empty?
            raise "Parameterized rule does not exist. `#{rule_name}`"
          else
            rules
          end
        end
      end
    end
  end
end
