# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Counterexamples
    class StateItem
      attr_reader :state #: State
      attr_reader :item #: States::Item

      # @rbs (State state, States::Item item) -> void
      def initialize(state, item)
        @state = state
        @item = item
      end

      # @rbs () -> (:start | :transition | :production)
      def type
        case
        when item.start_item?
          :start
        when item.beginning_of_rule?
          :production
        else
          :transition
        end
      end
    end
  end
end
