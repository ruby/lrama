# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Counterexamples
    class ProductionPath < Path
      # @rbs () -> :production
      def type
        :production
      end

      # @rbs () -> false
      def transition?
        false
      end

      # @rbs () -> true
      def production?
        true
      end
    end
  end
end
