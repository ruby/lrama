# frozen_string_literal: true

module Lrama
  module Backend
    class C < Base
      class ReferenceTranslator < Backend::ReferenceTranslator
        private

        def translate_lhs_value(ref, rule, grammar)
          tag = ref.ex_tag || lhs(rule).tag

          if tag
            "(yyval.#{tag.member})"
          elsif union_not_defined?(grammar)
            "(yyval)"
          else
            raise_tag_not_found_error(ref, rule)
          end
        end

        def translate_lhs_location(_ref, _rule, _grammar)
          "(yyloc)"
        end

        def translate_lhs_index(_ref, _rule, _grammar)
          raise "$:$ is not supported"
        end

        def translate_rhs_value(ref, rule, grammar)
          i = stack_index(ref, rule)
          tag = ref.ex_tag || rhs(rule)[ref.index - 1].tag

          if tag
            "(yyvsp[#{i}].#{tag.member})"
          elsif union_not_defined?(grammar)
            "(yyvsp[#{i}])"
          else
            raise_tag_not_found_error(ref, rule)
          end
        end

        def translate_rhs_location(ref, rule, _grammar)
          "(yylsp[#{stack_index(ref, rule)}])"
        end

        def translate_rhs_index(ref, rule, _grammar)
          "(#{stack_index(ref, rule)} - 1)"
        end

        def stack_index(ref, rule)
          -position_in_rhs(rule) + ref.index
        end

        def position_in_rhs(rule)
          rule.position_in_original_rule_rhs || rule.rhs.count
        end

        def rhs(rule)
          (rule.original_rule || rule).rhs
        end

        def lhs(rule)
          rule.lhs
        end

        def union_not_defined?(grammar)
          grammar.union.nil?
        end

        def raise_tag_not_found_error(ref, rule)
          raise "Tag is not specified for '$#{ref.value}' in '#{rule.display_name}'"
        end
      end
    end
  end
end
