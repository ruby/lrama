# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Counterexamples
    class TransitionPath < Path
      # @rbs () -> :transition
      def type
        :transition
      end

      # @rbs () -> true
      def transition?
        true
      end

      # @rbs () -> false
      def production?
        false
      end
    end
  end
end
