# frozen_string_literal: true

module Lrama
  class TraceReporter
    def initialize(grammar)
      @grammar = grammar
    end

    def report(**options)
      _report(**options)
    end

    private

    def _report(rules: false, actions: false, **_)
      report_rules if rules
      report_actions if actions
    end

    def report_rules
      puts "Grammar rules:"
      @grammar.rules.each do |rule|
        puts rule.display_name_without_action if rule.lhs.first_set.any?
      end
    end

    def report_actions
      puts "Grammar rules with actions:"
      @grammar.rules.each { |rule| puts rule.with_actions }
    end
  end
end
