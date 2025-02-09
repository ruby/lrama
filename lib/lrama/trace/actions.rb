# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Trace
    class Actions
      # @rbs (Lrama::Grammar grammar, bool actions, **untyped _) -> void
      def self.report(grammar, actions: false, **_)
        return unless actions

        puts "Grammar rules with actions:"
        grammar.rules.each { |rule| puts rule.with_actions }
      end
    end
  end
end
