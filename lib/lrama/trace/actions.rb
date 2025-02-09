# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Trace
    class Actions
      # @rbs (Lrama::Logger logger, **untyped _) -> void
      def initialize(logger, **options)
        @logger = logger
        @actions = options[:actions]
      end

      # @rbs (Lrama::Grammar grammar) -> void
      def trace(grammar)
        return unless @actions

        @logger.trace("Grammar rules with actions:")
        grammar.rules.each { |rule| @logger.trace(rule.with_actions) }
      end
    end
  end
end
