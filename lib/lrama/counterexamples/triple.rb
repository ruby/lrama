# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Counterexamples
    class Triple
      attr_reader :precise_lookahead_set #: Bitmap::bitmap

      alias :l :precise_lookahead_set

      # @rbs (StateItem state_item, Bitmap::bitmap precise_lookahead_set) -> void
      def initialize(state_item, precise_lookahead_set)
        @state_item = state_item
        @precise_lookahead_set = precise_lookahead_set
      end

      # @rbs () -> Integer
      def hash
        [state.id, item.hash, @precise_lookahead_set].hash
      end

      # @rbs (Triple other) -> bool
      def eql?(other)
        self.class == other.class &&
        self.state.id == other.state.id &&
        self.item == other.item &&
        self.precise_lookahead_set == other.precise_lookahead_set
      end

      # @rbs () -> State
      def state
        @state_item.state
      end
      alias :s :state

      # @rbs () -> States::Item
      def item
        @state_item.item
      end
      alias :itm :item

      # @rbs () -> StateItem
      def state_item
        @state_item
      end

      # @rbs () -> ::String
      def inspect
        "#{state.inspect}. #{item.display_name}. #{l.to_s(2)}"
      end
      alias :to_s :inspect
    end
  end
end
