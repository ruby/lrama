# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Warnings
    class Conflicts
      # @rbs (Lrama::Logger logger, bool warnings) -> void
      def initialize(logger, warnings)
        @emitter = Lrama::Diagnostic::Emitter.new(logger)
        @warnings = warnings
      end

      # @rbs (Lrama::States states) -> void
      def warn(states)
        diagnostics(states).each do |diagnostic|
          @emitter.warn(diagnostic)
        end
      end

      # @rbs (Lrama::States states) -> Array[Lrama::Diagnostic]
      def diagnostics(states)
        return [] unless @warnings

        diagnostics = [] #: Array[Lrama::Diagnostic]

        if states.sr_conflicts_count != 0
          diagnostics << Lrama::Diagnostic.new(
            id: "conflict.shift_reduce",
            severity: :warning,
            message: "shift/reduce conflicts: #{states.sr_conflicts_count} found",
            details: { "count" => states.sr_conflicts_count }
          )
        end

        if states.rr_conflicts_count != 0
          diagnostics << Lrama::Diagnostic.new(
            id: "conflict.reduce_reduce",
            severity: :warning,
            message: "reduce/reduce conflicts: #{states.rr_conflicts_count} found",
            details: { "count" => states.rr_conflicts_count }
          )
        end

        diagnostics
      end
    end
  end
end
