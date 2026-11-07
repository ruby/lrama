# rbs_inline: enabled
# frozen_string_literal: true

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
          resolve_rhs(builder, rhs, index, node, rule)
          builder.lhs = @rule_builder.lhs
          builder.lhs_location = @rule_builder.lhs_location
          builder.lhs_alias_name = @rule_builder.lhs_alias_name
          builder.line = @rule_builder.line
          builder.precedence_sym = @rule_builder.precedence_sym
          builder.action = replace_action(rhs, index)
          builder
        end

        # @rbs (Lrama::Grammar::RuleBuilder builder, Lrama::Grammar::Parameterized::Rhs rhs, Integer index, Node::RuleRhs::value node, Lrama::Grammar::Parameterized::Rule rule) -> void
        def resolve_rhs(builder, rhs, index, node, rule)
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
            else
              builder.add_rhs(rhs_node)
            end
          end
        end

        # @rbs (Lrama::Grammar::Parameterized::Rhs rhs, Integer index) -> Node::RuleRhs::Action?
        def replace_action(rhs, index)
          action = @rule_builder.action
          return action if rhs.action.nil? || action.nil?

          inline_index = index + 1
          index_offset = rhs.symbols.count - 1
          code = action.code.s_value.dup

          action.code.references.reverse_each do |ref|
            next if ref.index.nil? || ref.index < inline_index # The index is nil for $$.

            reference = code[ref.first_column...ref.last_column]
            replacement =
              if ref.type == :dollar && ref.index == inline_index
                rhs.action.code.s_value
              else
                reference.sub(/\d+\z/, (ref.index + index_offset).to_s)
              end
            code[ref.first_column...ref.last_column] = replacement
          end
          resolved_code = Lrama::Lexer::Token::UserCode.new(s_value: code, location: action.code.location)
          Node::RuleRhs::Action.new(
            code: resolved_code,
            alias_name: action.alias_name,
            tag: action.tag,
            location: action.location
          )
        end
      end
    end
  end
end
