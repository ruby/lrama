module Lrama
  class Grammar
    class Symbols
      class Base
        attr_reader :symbols

        # YYEMPTY = -2
        # YYEOF   =  0
        # YYerror =  1
        # YYUNDEF =  2
        INITIAL_NUMBER = 3

        def initialize
          @symbols = []
        end

        def count
          @symbols.count
        end
      end
    end
  end
end
