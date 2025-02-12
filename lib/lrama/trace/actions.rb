# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Trace
    class Actions
      # @rbs (IO io, **untyped _) -> void
      def initialize(io, **options)
        @io = io
        @actions = options[:actions]
      end

      # @rbs (Lrama::Grammar grammar) -> void
      def trace(grammar)
        return unless @actions

        @io << "Grammar rules with actions:" << "\n"
        grammar.rules.each { |rule| @io << rule.with_actions << "\n" }
      end
    end
  end
end
