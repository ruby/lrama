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
          when ref.value == "$" && ref.type == :dollar # $$
            member = ref.tag.member
            str = "(yyval.#{member})"
          when ref.value == "$" && ref.type == :at # @$
            str = "(yyloc)"
          when ref.type == :dollar # $n
            i = -ref.position_in_rhs + ref.value
            member = ref.tag.member
            str = "(yyvsp[#{i}].#{member})"
          when ref.type == :at # @n
            i = -ref.position_in_rhs + ref.value
            str = "(yylsp[#{i}])"
          else
            raise "Unexpected. #{self}, #{ref}"
          end
        end
      end
    end
  end
end
