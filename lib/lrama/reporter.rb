# rbs_inline: enabled
# frozen_string_literal: true

require_relative 'reporter/conflicts'
require_relative 'reporter/grammar'
require_relative 'reporter/profile'
require_relative 'reporter/rules'
require_relative 'reporter/states'
require_relative 'reporter/terms'

module Lrama
  class Reporter
    include Lrama::Tracer::Duration

    # @rbs (**Hash[Symbol, bool] options) -> void
    def initialize(**options)
      @options = options
      @rules = Rules.new(**options)
      @terms = Terms.new(**options)
      @conflicts = Conflicts.new
      @grammar = Grammar.new(**options)
      @states = States.new(**options)
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
