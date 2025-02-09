# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Report
    class Conflicts
      # @rbs (Lrama::States states, File io, **untyped _) -> void
      def self.report(states, io, **_)
        new(states, io).report
      end

      # @rbs (Lrama::States states, File io) -> void
      def initialize(states, io)
        @states = states
        @io = io
      end

      # @rbs () -> void
      def report
        has_conflict = false

        @states.states.each do |state|
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
            @io << "State #{state.id} conflicts: #{messages.join(', ')}\n"
          end
        end

        if has_conflict
          @io << "\n\n"
        end
      end
    end
  end
end
