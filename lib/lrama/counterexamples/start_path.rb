# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Counterexamples
    class StartPath < Path
      # @rbs (StateItem to_state_item) -> void
      def initialize(to_state_item)
        super nil, to_state_item
      end

      # @rbs () -> :start
      def type
        :start
      end

      # @rbs () -> false
      def transition?
        false
      end

      # @rbs () -> false
      def production?
        false
      end
    end
  end
end
