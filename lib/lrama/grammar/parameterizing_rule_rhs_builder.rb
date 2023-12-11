module Lrama
  class Grammar
    class ParameterizingRuleRhsBuilder
      attr_accessor :symbol, :user_code, :precedence_sym

      def initialize
        @symbol = nil
        @user_code = nil
        @precedence_sym = nil
      end
    end
  end
end
