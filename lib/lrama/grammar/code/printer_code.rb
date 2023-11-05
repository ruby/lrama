module Lrama
  class Grammar
    class Code
      class PrinterCode < Code
        def initialize(type: nil, token_code: nil, tag: nil)
          super(type: type, token_code: token_code)
          @tag = tag
        end

        private

        # * ($$) *yyvaluep
        # * (@$) *yylocationp
        # * ($1) error
        # * (@1) error
        def reference_to_c(ref)
          case
          when ref.value == "$" && ref.type == :dollar # $$
            member = @tag.member
            str = "((*yyvaluep).#{member})"
          when ref.value == "$" && ref.type == :at # @$
            str = "(*yylocationp)"
          when ref.type == :dollar # $n
            raise "$#{ref.value} can not be used in #{type}."
          when ref.type == :at # @n
            raise "@#{ref.value} can not be used in #{type}."
          else
            raise "Unexpected. #{self}, #{ref}"
          end
        end
      end
    end
  end
end
