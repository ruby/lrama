module Lrama
  class Grammar
    class ParameterizingRule
      class Rhs
        attr_accessor :symbols, :user_code, :precedence_sym

        def initialize
          @symbols = []
          @user_code = nil
          @precedence_sym = nil
        end

        def resolve_user_code(bindings)
          return unless user_code

          code = user_code.s_value
          symbols.each do |sym|
            resolved_sym = bindings.resolve_symbol(sym)
            if resolved_sym != sym
              code = code.gsub(/\$#{sym.s_value}/, "$#{resolved_sym.s_value}")
            end
          end
          Lrama::Lexer::Token::UserCode.new(s_value: code, location: user_code.location)
        end
      end
    end
  end
end
