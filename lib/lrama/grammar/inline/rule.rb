module Lrama
  class Grammar
    class Inline
      class Rule
        attr_reader :name, :rhs_list

        def initialize(name, rhs_list)
          @name = name
          @rhs_list = rhs_list
        end
      end
    end
  end
end
