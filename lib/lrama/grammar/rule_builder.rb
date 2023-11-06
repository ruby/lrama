module Lrama
  class Grammar
    class RuleBuilder
      attr_accessor :lhs, :line
      attr_reader :rhs

      def initialize
        @lhs = nil
        @rhs = []
        @user_code = nil
        @precedence_sym = nil
        @line = nil
      end

      def add_rhs(rhs)
        if !@line
          @line = rhs.line
        end

        @rhs << rhs
      end

      def user_code=(user_code)
        @rhs << user_code
      end

      def precedence_sym=(precedence_sym)
        @rhs << precedence_sym
      end
    end
  end
end