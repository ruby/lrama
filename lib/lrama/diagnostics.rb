# frozen_string_literal: true

module Lrama
  class Diagnostics
    def initialize(grammar, states, logger)
      @grammar = grammar
      @states = states
      @logger = logger
    end

    def run(conflicts_sr: false, conflicts_rr: false, parameterizing_redefined: false)
      diagnose_conflict(conflicts_sr, conflicts_rr)
      diagnose_parameterizing_redefined if parameterizing_redefined
    end

    private

    def diagnose_conflict(conflicts_sr, conflicts_rr)
      if conflicts_sr && @states.sr_conflicts_count != 0
        @logger.warn("shift/reduce conflicts: #{@states.sr_conflicts_count} found")
      end

      if conflicts_rr && @states.rr_conflicts_count != 0
        @logger.warn("reduce/reduce conflicts: #{@states.rr_conflicts_count} found")
      end
    end

    def diagnose_parameterizing_redefined
      @grammar.parameterizing_rule_resolver.redefined_rules.each do |rule|
        @logger.warn("parameterizing rule redefined: #{rule}")
      end
    end
  end
end
