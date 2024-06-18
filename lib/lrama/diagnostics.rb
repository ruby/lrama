# frozen_string_literal: true

module Lrama
  class Diagnostics
    def initialize(states, logger)
      @states = states
      @logger = logger
    end

    def run(conflicts_sr: false, conflicts_rr: false)
      diagnose_conflict(conflicts_sr, conflicts_rr)
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
  end
end
