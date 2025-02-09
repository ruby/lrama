# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Trace
    class Rules
      # @rbs (Lrama::Grammar grammar, bool rules, bool only_explicit, **untyped _) -> void
      def self.report(grammar, rules: false, only_explicit: false, **_)
        return if !rules || only_explicit

        puts "Grammar rules:"
        grammar.rules.each { |rule| puts rule.display_name }
      end
    end
  end
end
