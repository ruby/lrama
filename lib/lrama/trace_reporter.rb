# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class TraceReporter
    # @rbs (Lrama::Grammar grammar) -> void
    def initialize(grammar)
      @grammar = grammar
    end

    # @rbs (**Hash[Symbol, bool] options) -> void
    def report(**options)
      _report(**options)
    end

    private

    # @rbs rules: (bool rules, bool actions, **untyped _) -> void
    def _report(rules: false, actions: false, **_)
      report_rules if rules
      report_actions if actions
    end

    # @rbs () -> void
    def report_rules
      puts "Grammar rules:"
      @grammar.rules.each { |rule| puts rule.display_name }
    end

    # @rbs () -> void
    def report_actions
      puts "Grammar rules with actions:"
      @grammar.rules.each { |rule| puts rule.with_actions }
    end
  end
end
