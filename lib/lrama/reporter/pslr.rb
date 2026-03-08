# frozen_string_literal: true

module Lrama
  class Reporter
    class Pslr
      # @rbs (?pslr: bool, **bool _) -> void
      def initialize(pslr: false, **_)
        @pslr = pslr
      end

      # @rbs (IO io, Lrama::States states) -> void
      def report(io, states)
        return unless @pslr
        return unless states.pslr_defined?

        metrics = states.pslr_metrics

        io << "PSLR Summary\n\n"
        io << "    Base states: #{metrics[:base_states_count]}\n"
        io << "    Total states: #{metrics[:total_states_count]}\n"
        io << "    Split states: #{metrics[:split_state_count]}\n"
        io << "    State growth: +#{metrics[:growth_count]} (#{format_ratio(metrics[:growth_ratio])})\n"
        io << "    Token patterns: #{metrics[:token_pattern_count]}\n"
        io << "    Scanner states: #{metrics[:scanner_fsa_state_count]}\n"
        io << "    Inadequacies: #{metrics[:inadequacies_count]}\n"
        io << "    Max states: #{states.pslr_max_states || 'unbounded'}\n"
        io << "    Max ratio: #{states.pslr_max_state_ratio || 'unbounded'}\n"
        io << "\n"
      end

      private

      # @rbs (Float?) -> String
      def format_ratio(value)
        return "n/a" if value.nil?

        "#{format('%.2f', value)}x"
      end
    end
  end
end
