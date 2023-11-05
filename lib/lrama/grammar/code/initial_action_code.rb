module Lrama
  class Grammar
    class Code
      class InitialActionCode < Code
        private

        # * ($$) yylval
        # * (@$) yylloc
        # * ($1) error
        # * (@1) error
        def reference_to_c(ref)
          case
          when ref.value == "$" && ref.type == :dollar # $$
            str = "yylval"
          when ref.value == "$" && ref.type == :at # @$
            str = "yylloc"
          when ref.type == :dollar # $n
            raise "$#{ref.value} can not be used in initial_action."
          when ref.type == :at # @n
            raise "@#{ref.value} can not be used in initial_action."
          else
            raise "Unexpected. #{self}, #{ref}"
          end
        end
      end
    end
  end
end
