module Lrama
  class Lexer
    class Token
      class ControlSyntax < Token
        attr_accessor :condition

        def initialize(s_value:, location:, condition: nil)
          @condition = condition
          super(s_value: s_value, location: location)
        end

        def if?
          s_value == '%if'
        end

        def endif?
          s_value == '%endif'
        end

        def true?
          !!@condition&.s_value
        end

        def false?
          !true?
        end

        def condition_value
          @condition&.s_value
        end
      end
    end
  end
end
