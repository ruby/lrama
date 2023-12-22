module Lrama
  class Lexer
    class Token
      class ParserStatePush < Token
        attr_accessor :state
      end
    end
  end
end
