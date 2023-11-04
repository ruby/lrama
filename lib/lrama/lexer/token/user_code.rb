module Lrama
  class Lexer
    class Token
      class UserCode < Token
        attr_accessor :references

        def initialize(args = {})
          super
          self.references = []
        end
      end
    end
  end
end
