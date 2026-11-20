# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Reporter
    class Conflicts
      # @rbs (IO io, Lrama::States states) -> void
      def report(io, states)
        report_conflicts(io, states)
      end

      private

      # @rbs (IO io, Lrama::States states) -> void
      def report_conflicts(io, states)
        has_conflict = false

        states.states.each do |state|
          messages = [] #: Array[String]
          sr_count = state.sr_conflicts_count
          rr_count = state.rr_conflicts_count
          messages << "#{sr_count} shift/reduce" if sr_count > 0
          messages << "#{rr_count} reduce/reduce" if rr_count > 0

          unless messages.empty?
            has_conflict = true
            io << "State #{state.id} conflicts: #{messages.join(', ')}\n"
          end
        end

        io << "\n\n" if has_conflict
      end
    end
  end
end
