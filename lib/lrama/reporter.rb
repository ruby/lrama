# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Reporter
    include Lrama::Trace::Duration

    # @rbs (Lrama::States states, File io, **untyped _) -> void
    def self.call(states, grammar, **options)
      new.call(states, grammar, **options)
    end

    # @rbs (Lrama::States states, File io, **untyped _) -> void
    def call(states, grammar, **options)
      report_duration(:report) do
        Lrama::Report::Rules.report(states, grammar, **options)
        Lrama::Report::Terms.report(states, grammar, **options)
        Lrama::Report::Conflicts.report(states, grammar, **options)
        Lrama::Report::Grammar.report(states, grammar, **options)
        Lrama::Report::States.report(states, grammar, **options)
      end
    end
  end
end
