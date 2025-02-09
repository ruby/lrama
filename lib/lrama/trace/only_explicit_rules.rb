# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Trace
    class OnlyExplicitRules
      # @rbs (Lrama::Logger logger, only_explicit: false, **untyped _) -> void
      def initialize(logger, only_explicit: false, **_)
        @logger = logger
        @only_explicit = only_explicit
      end

      # @rbs (Lrama::Grammar grammar) -> void
      def trace(grammar)
        return unless @only_explicit

        @logger.trace("Grammar rules:")
        grammar.rules.each do |rule|
          @logger.trace(rule.display_name_without_action) if rule.lhs.first_set.any?
        end
      end
    end
  end
end
