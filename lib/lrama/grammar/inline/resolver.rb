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
          @rule_builder.rhs.each_with_index do |token, i|
            if (rule = @rule_builder.parameterized_resolver.find_inline(token))
              rule.rhs.each do |rhs|
                builder = build_rule(rhs, token, i, rule)
                resolved_builders << builder
              end
              break
            end
          end
          resolved_builders
        end

        private

        # @rbs (Lrama::Grammar::Parameterized::Rhs rhs, Lrama::Lexer::Token token, Integer index, Lrama::Grammar::Parameterized::Rule rule) -> Lrama::Grammar::RuleBuilder
        def build_rule(rhs, token, index, rule)
          builder = RuleBuilder.new(
            @rule_builder.rule_counter,
            @rule_builder.midrule_action_counter,
            @rule_builder.parameterized_resolver,
            lhs_tag: @rule_builder.lhs_tag
          )
          resolve_rhs(builder, rhs, index, token, rule)
          builder.lhs = @rule_builder.lhs
          builder.line = @rule_builder.line
          builder.precedence_sym = @rule_builder.precedence_sym
          builder.user_code = replace_user_code(rhs, index)
          builder
        end

        # @rbs (Lrama::Grammar::RuleBuilder builder, Lrama::Grammar::Parameterized::Rhs rhs, Integer index, Lrama::Lexer::Token token, Lrama::Grammar::Parameterized::Rule rule) -> void
        def resolve_rhs(builder, rhs, index, token, rule)
          @rule_builder.rhs.each_with_index do |tok, i|
            if i == index
              rhs.symbols.each do |sym|
                if token.is_a?(Lexer::Token::InstantiateRule)
                  bindings = Binding.new(rule.parameters, token.args)
                  builder.add_rhs(bindings.resolve_symbol(sym))
                else
                  builder.add_rhs(sym)
                end
              end
            else
              builder.add_rhs(tok)
            end
          end
        end

        # @rbs (Lrama::Grammar::Parameterized::Rhs rhs, Integer index) -> Lrama::Lexer::Token::UserCode
        def replace_user_code(rhs, index)
          user_code = @rule_builder.user_code
          return user_code if rhs.user_code.nil? || user_code.nil?

          inline_action = rhs.user_code.s_value
          inline_var = "_inline_#{index + 1}"

          # Replace $$ or $<tag>$ in inline action with the temporary variable
          # $$ -> _inline_n, $<tag>$ -> _inline_n.tag
          inline_action_with_var = inline_action.gsub(/\$(<(\w+)>)?\$/) do |_match|
            if $2
              "#{inline_var}.#{$2}"
            else
              inline_var
            end
          end

          # Build the merged action with variable binding
          # First, adjust $n references in the outer action for the expanded RHS
          # index is 0-indexed position, ref.index is 1-indexed ($1, $2, etc.)
          # We need to adjust references AFTER the inline position (index + 1 in 1-indexed terms)
          # So we skip: nil ($$), and positions <= index + 1 (the inline position itself)
          outer_code = user_code.s_value
          user_code.references.each do |ref|
            next if ref.index.nil? || ref.index <= index + 1 # nil is $$, index + 1 is inline position
            outer_code = outer_code.gsub(/\$#{ref.index}/, "$#{ref.index + (rhs.symbols.count - 1)}")
            outer_code = outer_code.gsub(/@#{ref.index}/, "@#{ref.index + (rhs.symbols.count - 1)}")
          end

          # Replace $n or $<tag>n (the inline symbol reference) with the temporary variable
          # $n -> _inline_n, $<tag>n -> _inline_n.tag
          outer_code = outer_code.gsub(/\$(<(\w+)>)?#{index + 1}/) do |_match|
            if $2
              "#{inline_var}.#{$2}"
            else
              inline_var
            end
          end

          # Combine: declare temp var, execute inline action, then outer action
          merged_code = " YYSTYPE #{inline_var}; { #{inline_action_with_var} } #{outer_code}"

          Lrama::Lexer::Token::UserCode.new(s_value: merged_code, location: user_code.location)
        end
      end
    end
  end
end
