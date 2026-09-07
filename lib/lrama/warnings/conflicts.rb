# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Warnings
    class Conflicts
      # @rbs (Lrama::Logger logger, bool warnings, counterexamples: bool) -> void
      def initialize(logger, warnings, counterexamples: false)
        @logger = logger
        @warnings = warnings
        @counterexamples = counterexamples
      end

      # @rbs (Lrama::States states) -> void
      def warn(states)
        return unless @warnings

        if states.sr_conflicts_count != 0
          @logger.warn("shift/reduce conflicts: #{states.sr_conflicts_count} found")
        end

        if states.rr_conflicts_count != 0
          @logger.warn("reduce/reduce conflicts: #{states.rr_conflicts_count} found")
        end

        return if states.sr_conflicts_count == 0 && states.rr_conflicts_count == 0

        if @counterexamples
          warn_counterexamples(states)
        else
          @logger.note("rerun with option '-Wcounterexamples' to generate conflict counterexamples")
        end
      end

      private

      # @rbs (Lrama::States states) -> void
      def warn_counterexamples(states)
        cex = Lrama::Counterexamples.new(states)
        first = true

        states.states.each do |state|
          next unless state.has_conflicts?

          cex.compute(state).each do |example|
            @logger.line_break if first
            first = false
            @logger.warn("#{example.type.to_s.tr('_', '/')} conflict on #{example.conflict_label} [-Wcounterexamples]")
            @logger.trace("  #{example.example1_label}: #{example.example1}")
            @logger.trace("  #{example.derivation_label1}")
            example.derivations1.render_strings_for_report.each do |line|
              @logger.trace("    #{line}")
            end
            @logger.trace("  #{example.example2_label}: #{example.example2}")
            @logger.trace("  #{example.derivation_label2}")
            example.derivations2.render_strings_for_report.each do |line|
              @logger.trace("    #{line}")
            end
          end
        end
      end

    end
  end
end
