# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Counterexamples
    class Path
      # @rbs!
      #   type path = StartPath | TransitionPath | ProductionPath
      #
      #   @state_item: StateItem

      attr_reader :state_item #: StateItem
      attr_reader :parent #: path?

      # @rbs (StateItem state_item, path? parent) -> void
      def initialize(state_item, parent)
        @state_item = state_item
        @parent = parent
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
