# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Report
    class Terms
      # @rbs (terms: bool, **untyped _) -> void
      def initialize(terms: false, **_)
        @terms = terms
      end

      # @rbs (Lrama::States states, Lrama::Logger logger) -> void
      def report(states, logger)
        return unless @terms

        look_aheads = states.states.each do |state|
          state.reduces.flat_map do |reduce|
            reduce.look_ahead unless reduce.look_ahead.nil?
          end
        end

        next_terms = states.states.flat_map do |state|
          state.shifts.map(&:next_sym).select(&:term?)
        end

        unused_symbols = states.terms.select do |term|
          !(look_aheads + next_terms).include?(term)
        end

        unless unused_symbols.empty?
          logger.trace("#{unused_symbols.count} Unused Terms\n")
          unused_symbols.each_with_index do |term, index|
            logger.trace(sprintf("%5d %s", index, term.id.s_value))
          end
          logger.trace("\n")
        end
      end
    end
  end
end
