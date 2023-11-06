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

      def freeze_rhs
        @rhs.freeze
      end

      def numberize_references
        (rhs + [user_code]).compact.each do |token|
          next unless token.class == Lrama::Lexer::Token::UserCode

          token.references.each do |ref|
            ref_name = ref.value
            if ref_name.is_a?(::String) && ref_name != '$'
              value =
                if lhs.referred_by?(ref_name)
                  '$'
                else
                  index = rhs.find_index {|token| token.referred_by?(ref_name) }

                  if index
                    index + 1
                  else
                    raise "'#{ref_name}' is invalid name."
                  end
                end

              ref.value = value
              ref
            end
          end
        end
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
