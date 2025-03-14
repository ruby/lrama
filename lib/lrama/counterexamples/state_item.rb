# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Counterexamples
    class StateItem < Struct.new(:state, :item)
      # @rbs!
      #   attr_accessor state: State
      #   attr_accessor item: States::Item
      #
      #   def initialize: (State state, States::Item item) -> void

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
