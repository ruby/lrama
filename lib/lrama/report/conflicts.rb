# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Report
    class Conflicts
      # (Lrama::States states, Lrama::Logger logger) -> void
      def report(states, logger)
        has_conflict = false

        states.states.each do |state|
          messages = [] #: Array[string]
          cs = state.conflicts.group_by(&:type)
          if cs[:shift_reduce]
            messages << "#{cs[:shift_reduce].count} shift/reduce"
          end

          if cs[:reduce_reduce]
            messages << "#{cs[:reduce_reduce].count} reduce/reduce"
          end

          unless messages.empty?
            has_conflict = true
            logger.trace("State #{state.id} conflicts: #{messages.join(', ')}")
          end
        end

        if has_conflict
          logger.trace("\n")
        end
      end
    end
  end
end
