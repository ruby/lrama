module Lrama
  class Lexer
    class Token
      class Parameterizing < Token
        def option?
          %w(option ?).include?(self.s_value)
        end

        def nonempty_list?
          %w(nonempty_list +).include?(self.s_value)
        end

        def list?
          %w(list *).include?(self.s_value)
        end
      end
    end
  end
end
