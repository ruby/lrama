# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Trace
    class OnlyExplicitRules
      # @rbs (Lrama::Grammar grammar, bool only_explicit, **untyped _) -> void
      def self.report(grammar, only_explicit: false, **_)
        return unless only_explicit

        puts "Grammar rules:"
        grammar.rules.each do |rule|
          puts rule.display_name_without_action if rule.lhs.first_set.any?
        end
      end
    end
  end
end
