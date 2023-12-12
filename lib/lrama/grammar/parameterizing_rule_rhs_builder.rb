module Lrama
  class Grammar
    class ParameterizingRuleRhsBuilder
      attr_accessor :symbols, :user_code, :precedence_sym

      def initialize
        @symbols = []
        @user_code = nil
        @precedence_sym = nil
      end
    end
  end
end
