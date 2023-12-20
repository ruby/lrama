module Lrama
  class Lexer
    class Token
      class InstantiateRule < Token
        attr_accessor :args

        def initialize(s_value:, alias_name: nil, location: nil, args: [])
          super s_value: s_value, alias_name: alias_name, location: location
          @args = args
        end
      end
    end
  end
end
