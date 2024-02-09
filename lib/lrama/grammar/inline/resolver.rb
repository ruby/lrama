module Lrama
  class Grammar
    class Inline
      class Resolver
        attr_accessor :rules

        def initialize
          @rules = []
        end

        def add_inline_rule(rule)
          @rules << rule
        end

        def find(token)
          @rules.select { |rule| rule.name == token.s_value }.last
        end
      end
    end
  end
end
