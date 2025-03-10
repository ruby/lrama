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
    end
  end
end
