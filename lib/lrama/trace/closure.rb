# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Trace
    class Closure
      # @rbs (Lrama::Logger logger, bool automaton, bool closure, **untyped _) -> void
      def initialize(logger, automaton: false, closure: false, **options)
        @logger = logger
        @closure = automaton || closure
      end

      # @rbs (Lrama::State state) -> void
      def trace(state)
        return unless @closure

        @logger.trace("Closure: input")
        state.kernels.each do |item|
          @logger.trace("  #{item.display_rest}")
        end
        @logger.trace("\n")
        @logger.trace("Closure: output")
        state.items.each do |item|
          @logger.trace("  #{item.display_rest}")
        end
        @logger.trace("\n")
      end
    end
  end
end
