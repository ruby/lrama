# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Tracer
    # @rbs (Logger logger, **Hash[Symbol, bool] options) -> void
    def initialize(logger, **options)
      @logger = logger
      @options = options
      @only_explicit_rules = Lrama::Trace::OnlyExplicitRules.new(logger, **options)
      @rules = Lrama::Trace::Rules.new(logger, **options)
      @actions = Lrama::Trace::Actions.new(logger, **options)
      @closure = Lrama::Trace::Closure.new(logger, **options)
      @state = Lrama::Trace::State.new(logger, **options)
    end

    # @rbs (Lrama::Grammar grammar) -> void
    def trace(grammar)
      @only_explicit_rules.trace(grammar)
      @rules.trace(grammar)
      @actions.trace(grammar)
    end

    # @rbs (Lrama::State state) -> void
    def trace_closure(state)
      @closure.trace(state)
    end

    # @rbs (Lrama::State state) -> void
    def trace_state(state)
      @state.trace(state)
    end

    # @rbs (Integer state_count, Lrama::State state) -> void
    def trace_state_list_append(state_count, state)
      @state.trace_list_append(state_count, state)
    end

    # @rbs () -> void
    def enable_duration
      Lrama::Trace::Duration.enable if @options[:time]
    end
  end
end
