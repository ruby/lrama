# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Counterexamples
    class Path
      # @rbs!
      #   type path = StartPath | TransitionPath | ProductionPath
      #
      #   @from_state_item: StateItem?
      #   @to_state_item: StateItem

      attr_reader :parent #: path?

      # @rbs (StateItem? from_state_item, StateItem to_state_item, path? parent) -> void
      def initialize(from_state_item, to_state_item, parent)
        @from_state_item = from_state_item
        @to_state_item = to_state_item
        @parent = parent
      end

      # @rbs () -> StateItem?
      def from
        @from_state_item
      end

      # @rbs () -> StateItem
      def to
        @to_state_item
      end

      # @rbs () -> ::String
      def to_s
        "#<Path(#{type})>"
      end
      alias :inspect :to_s

      # @rbs () -> bot
      def type
        raise NotImplementedError
      end
    end
  end
end
