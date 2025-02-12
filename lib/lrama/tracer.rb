# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Tracer
    # @rbs (IO io, **Hash[Symbol, bool] options) -> void
    def initialize(io, **options)
      @io = io
      @options = options
      @only_explicit_rules = Lrama::Trace::OnlyExplicitRules.new(io, **options)
      @rules = Lrama::Trace::Rules.new(io, **options)
      @actions = Lrama::Trace::Actions.new(io, **options)
      @closure = Lrama::Trace::Closure.new(io, **options)
      @state = Lrama::Trace::State.new(io, **options)
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
