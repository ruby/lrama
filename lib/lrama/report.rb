# rbs_inline: enabled
# frozen_string_literal: true

require_relative 'report/conflicts'
require_relative 'report/grammar'
require_relative 'report/profile'
require_relative 'report/rules'
require_relative 'report/states'
require_relative 'report/terms'

module Lrama
  class Report
    include Lrama::Trace::Duration

    # @rbs (Lrama::States states, File io, **untyped _) -> void
    def self.report(states, grammar, **options)
      new.report(states, grammar, **options)
    end

    # @rbs (Lrama::States states, File io, **untyped _) -> void
    def report(states, grammar, **options)
      report_duration(:report) do
        Rules.report(states, grammar, **options)
        Terms.report(states, grammar, **options)
        Conflicts.report(states, grammar, **options)
        Grammar.report(states, grammar, **options)
        States.report(states, grammar, **options)
      end
    end
  end
end
