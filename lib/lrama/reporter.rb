# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Reporter
    include Lrama::Trace::Duration

    # @rbs (**Hash[Symbol, bool] options) -> void
    def initialize(**options)
      @options = options
      @rules = Lrama::Report::Rules.new(**options)
      @terms = Lrama::Report::Terms.new(**options)
      @conflicts = Lrama::Report::Conflicts.new
      @grammar = Lrama::Report::Grammar.new(**options)
      @states = Lrama::Report::States.new(**options)
    end

    # @rbs (File io, Lrama::States states) -> void
    def report(io, states)
      report_duration(:report) do
        @rules.report(io, states)
        @terms.report(io, states)
        @conflicts.report(io, states)
        @grammar.report(io, states)
        @states.report(io, states)
      end
    end
  end
end
