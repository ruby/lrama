module Lrama
  class Grammar
    class RuleBuilder
      attr_accessor :lhs, :line
      attr_reader :rhs, :user_code, :precedence_sym

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

        flush_user_code

        @rhs << rhs
      end

      def user_code=(user_code)
        flush_user_code

        @user_code = user_code
      end

      def precedence_sym=(precedence_sym)
        flush_user_code

        @precedence_sym = precedence_sym
      end

      private

      def flush_user_code
        if @user_code
          @rhs << @user_code
          @user_code = nil
        end
      end
    end
  end
end
