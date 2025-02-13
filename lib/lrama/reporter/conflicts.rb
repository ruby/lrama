# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Reporter
    class Conflicts
      # (IO io, Lrama::States states) -> void
      def report(io, states)
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
            io << "State #{state.id} conflicts: #{messages.join(', ')}\n"
          end
        end

        if has_conflict
          io << "\n\n"
        end
      end
    end
  end
end
