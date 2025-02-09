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

    # @rbs (Lrama::States states, File io) -> void
    def report(states, io)
      report_duration(:report) do
        logger = Lrama::Logger.new(io)
        @rules.report(states, logger)
        @terms.report(states, logger)
        @conflicts.report(states, logger)
        @grammar.report(states, logger)
        @states.report(states, logger)
      end
    end
  end
end
