module Lrama
  class Lexer
    class Token
      class Type < Struct.new(:id, :name, keyword_init: true)
      end
    end
  end
end
