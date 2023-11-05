module Lrama
  class Grammar
    class Code
      class RuleAction < Code
        private

        # * ($$) yyval
        # * (@$) yyloc
        # * ($1) yyvsp[i]
        # * (@1) yylsp[i]
        def reference_to_c(ref)
          case
          when ref.type == :dollar && ref.value == "$" # $$
            member = ref.tag.member
            "(yyval.#{member})"
          when ref.type == :at && ref.value == "$" # @$
            "(yyloc)"
          when ref.type == :dollar # $n
            i = -ref.position_in_rhs + ref.value
            member = ref.tag.member
            "(yyvsp[#{i}].#{member})"
          when ref.type == :at # @n
            i = -ref.position_in_rhs + ref.value
            "(yylsp[#{i}])"
          else
            raise "Unexpected. #{self}, #{ref}"
          end
        end
      end
    end
  end
end
