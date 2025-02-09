# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Trace
    class Rules
      # @rbs (Lrama::Logger logger, bool rules, bool only_explicit, **untyped _) -> void
      def initialize(logger, rules: false, only_explicit: false, **_)
        @logger = logger
        @rules = rules
        @only_explicit = only_explicit
      end

      # @rbs (Lrama::Grammar grammar) -> void
      def trace(grammar)
        return if !@rules || @only_explicit

        @logger.trace("Grammar rules:")
        grammar.rules.each { |rule| @logger.trace(rule.display_name) }
      end
    end
  end
end
