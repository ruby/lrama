# rbs_inline: enabled
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

        report_summary(io, states)
        report_acceptable_tokens(io, states)
        report_scanner_accepts(io, states)
        report_unresolved_conflicts(io, states)
        report_useless_lex_prec(io, states)
        report_tie_candidates(io, states)
      end

      private

      # @rbs (IO io, Lrama::States states) -> void
      def report_summary(io, states)
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

      # @rbs (IO io, Lrama::States states) -> void
      def report_acceptable_tokens(io, states)
        return unless states.scanner_fsa

        io << "PSLR Acceptable Tokens (acc with ties and layout)\n\n"
        states.states.each do |state|
          tokens = states.pslr_acceptable_tokens(state).to_a.sort
          io << "    State #{state.id}: #{tokens.join(' ')}\n"
        end
        io << "\n"
      end

      # @rbs (IO io, Lrama::States states) -> void
      def report_scanner_accepts(io, states)
        scanner_accepts = states.scanner_accepts_table
        scanner_fsa = states.scanner_fsa
        return unless scanner_accepts && scanner_fsa

        accepting_states = scanner_fsa.states.select(&:accepting?)

        io << "PSLR Scanner Accepts\n\n"
        states.states.each do |state|
          cells = accepting_states.filter_map do |fsa_state|
            token = scanner_accepts[state.id, fsa_state.id]
            "ss#{fsa_state.id}=>#{token.name}" if token
          end
          next if cells.empty?

          io << "    State #{state.id}: #{cells.join(' ')}\n"
        end

        fallback_cells = accepting_states.filter_map do |fsa_state|
          token = scanner_accepts.fallback_table[fsa_state.id]
          "ss#{fsa_state.id}=>#{token.name}" if token
        end
        io << "    Fallback: #{fallback_cells.join(' ')}\n" unless fallback_cells.empty?
        io << "\n"
      end

      # @rbs (IO io, Lrama::States states) -> void
      def report_unresolved_conflicts(io, states)
        scanner_accepts = states.scanner_accepts_table
        return unless scanner_accepts
        return unless scanner_accepts.unresolved_conflicts?

        io << "PSLR Unresolved Scanner Conflicts\n\n"
        scanner_accepts.conflicts.each do |conflict|
          io << "    State #{conflict.parser_state_id || 'fallback'}, scanner state #{conflict.scanner_state_id}\n"
          io << "        witness: #{conflict.witness.inspect}\n" if conflict.witness
          io << "        shorter matches: #{conflict.shorter_tokens.join(', ')}\n" unless conflict.shorter_tokens.empty?
          io << "        current matches: #{conflict.current_tokens.join(', ')}\n"
        end
        io << "\n"
      end

      # @rbs (IO io, Lrama::States states) -> void
      def report_useless_lex_prec(io, states)
        return unless states.scanner_accepts_table

        useless = states.lex_prec.useless_rules
        return if useless.empty?

        io << "PSLR Useless %lex-prec Rules\n\n"
        useless.each do |rule|
          operator = LengthPrecedences.operator_label(rule.operator)
          io << "    #{rule.left_name} #{operator} #{rule.right_name} (line #{rule.lineno})\n"
        end
        io << "\n"
      end

      # @rbs (IO io, Lrama::States states) -> void
      def report_tie_candidates(io, states)
        candidates = states.lexical_tie_candidates
        return if candidates.nil? || candidates.empty?

        io << "PSLR Lexical Tie Candidates\n\n"
        candidates.each do |left, right|
          io << "    #{left} #{right}\n"
        end
        io << "\n"
      end

      # @rbs (Numeric?) -> String
      def format_ratio(value)
        return "n/a" if value.nil?

        "#{format('%.2f', value)}x"
      end
    end
  end
end
