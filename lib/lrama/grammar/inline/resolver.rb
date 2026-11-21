# rbs_inline: enabled
# frozen_string_literal: true

require_relative "action"

module Lrama
  class Grammar
    class Inline
      class Resolver
        # @rbs (Lrama::Grammar::RuleBuilder rule_builder) -> void
        def initialize(rule_builder)
          @rule_builder = rule_builder
        end

        # @rbs () -> Array[Lrama::Grammar::RuleBuilder]
        def resolve
          resolved_builders = []  #: Array[Lrama::Grammar::RuleBuilder]
          @rule_builder.rhs.each_with_index do |node, i|
            next unless node.is_a?(Node::RuleRhs::Symbol) || node.is_a?(Node::RuleRhs::InstantiateRule)

            if (rule = @rule_builder.parameterized_resolver.find_inline(node))
              rule.rhs.each do |rhs|
                builder = build_rule(rhs, node, i, rule)
                resolved_builders << builder
              end
              break
            end
          end
          resolved_builders
        end

        private

        # @rbs (Lrama::Grammar::Parameterized::Rhs rhs, Node::RuleRhs::value node, Integer index, Lrama::Grammar::Parameterized::Rule rule) -> Lrama::Grammar::RuleBuilder
        def build_rule(rhs, node, index, rule)
          builder = RuleBuilder.new(
            @rule_builder.rule_counter,
            @rule_builder.midrule_action_counter,
            @rule_builder.parameterized_resolver,
            lhs_tag: @rule_builder.lhs_tag
          )
          tag = node.is_a?(Node::RuleRhs::InstantiateRule) ? node.lhs_tag || rule.tag : rule.tag
          actions = Action.new(@rule_builder, rule, rhs, index, tag)
          resolve_rhs(builder, rhs, index, node, rule, actions)
          builder.lhs = @rule_builder.lhs
          builder.lhs_location = @rule_builder.lhs_location
          builder.lhs_alias_name = @rule_builder.lhs_alias_name
          builder.line = @rule_builder.line
          builder.precedence_sym = @rule_builder.precedence_sym
          if (action = actions.expand)
            builder.add_rhs(action)
          end
          builder.complete_input
          builder
        end

        # @rbs (Lrama::Grammar::RuleBuilder builder, Lrama::Grammar::Parameterized::Rhs rhs, Integer index, Node::RuleRhs::value node, Lrama::Grammar::Parameterized::Rule rule, Action actions) -> void
        def resolve_rhs(builder, rhs, index, node, rule, actions)
          @rule_builder.rhs.each_with_index do |rhs_node, i|
            if i == index
              rhs.symbols.each do |sym|
                if node.is_a?(Node::RuleRhs::InstantiateRule)
                  bindings = Binding.new(rule.parameters, node.args)
                  builder.add_rhs(bindings.resolve_symbol(sym))
                else
                  builder.add_rhs(sym)
                end
              end
              if (stack_action = actions.stack_action)
                builder.add_rhs(stack_action)
              end
            elsif i > index && rhs_node.is_a?(Node::RuleRhs::Action)
              builder.add_rhs(actions.rewrite_midrule(rhs_node, i + 1))
            else
              builder.add_rhs(rhs_node)
            end
          end
        end
      end
    end
  end
end
