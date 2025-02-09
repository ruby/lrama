# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Report
    class Terms
      # @rbs (Lrama::States states, File io, terms: bool, **untyped _) -> void
      def self.report(states, io, terms: false, **_)
        new(states, io).report if terms
      end

      # @rbs (Lrama::States states, File io) -> void
      def initialize(states, io)
        @states = states
        @io = io
      end

      # @rbs () -> void
      def report
        look_aheads = @states.states.each do |state|
          state.reduces.flat_map do |reduce|
            reduce.look_ahead unless reduce.look_ahead.nil?
          end
        end

        next_terms = @states.states.flat_map do |state|
          state.shifts.map(&:next_sym).select(&:term?)
        end

        unused_symbols = @states.terms.select do |term|
          !(look_aheads + next_terms).include?(term)
        end

        unless unused_symbols.empty?
          @io << "#{unused_symbols.count} Unused Terms\n\n"
          unused_symbols.each_with_index do |term, index|
            @io << sprintf("%5d %s\n", index, term.id.s_value)
          end
          @io << "\n\n"
        end
      end
    end
  end
end
