# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Reporter
    class States
      # @rbs (itemsets: bool, lookaheads: bool, solved: bool, counterexamples: bool, verbose: bool, **untyped _) -> void
      def initialize(itemsets: false, lookaheads: false, solved: false, counterexamples: false, verbose: false, **_)
        @itemsets = itemsets
        @lookaheads = lookaheads
        @solved = solved
        @counterexamples = counterexamples
        @verbose = verbose
      end

      # @rbs (IO io, Lrama::States states) -> void
      def report(io, states)
        cex = Counterexamples.new(states) if @counterexamples

        states.states.each do |state|
          report_state_header(io, state)
          report_items(io, state)
          report_conflicts(io, state)
          report_shifts(io, state)
          report_nonassoc_errors(io, state)
          report_reduces(io, state)
          report_nterm_transitions(io, state)
          report_conflict_resolutions(io, state) if @solved
          report_counterexamples(io, state, cex) if @counterexamples && state.has_conflicts? # @type var cex: Lrama::Counterexamples
          report_verbose_info(io, state, states) if @verbose
          # End of Report State
          io << "\n"
        end
      end

      private

      # @rbs (IO io, Lrama::State state) -> void
      def report_state_header(io, state)
        io << "State #{state.id}\n\n"
      end

      # @rbs (IO io, Lrama::State state) -> void
      def report_items(io, state)
        last_lhs = nil
        list = @itemsets ? state.items : state.kernels

        list.sort_by {|i| [i.rule_id, i.position] }.each do |item|
          r = item.empty_rule? ? "ε •" : item.rhs.map(&:display_name).insert(item.position, "•").join(" ")

          l = if item.lhs == last_lhs
            " " * item.lhs.id.s_value.length + "|"
          else
            item.lhs.id.s_value + ":"
          end

          la = ""
          if @lookaheads && item.end_of_rule?
            reduce = state.find_reduce_by_item!(item)
            look_ahead = reduce.selected_look_ahead
            unless look_ahead.empty?
              la = "  [#{look_ahead.compact.map(&:display_name).join(", ")}]"
            end
          end

          last_lhs = item.lhs
          io << sprintf("%5i %s %s%s", item.rule_id, l, r, la) << "\n"
        end

        io << "\n"
      end

      # @rbs (IO io, Lrama::State state) -> void
      def report_conflicts(io, state)
        return if state.conflicts.empty?

        state.conflicts.each do |conflict|
          syms = conflict.symbols.map { |sym| sym.id.s_value }
          io << "    Conflict on #{syms.join(", ")}. "

          case conflict.type
          when :shift_reduce
            # @type var conflict: Lrama::State::ShiftReduceConflict
            io << "shift/reduce(#{conflict.reduce.item.rule.lhs.display_name})\n"
          when :reduce_reduce
            # @type var conflict: Lrama::State::ReduceReduceConflict
            io << "reduce(#{conflict.reduce1.item.rule.lhs.display_name})/reduce(#{conflict.reduce2.item.rule.lhs.display_name})\n"
          else
            raise "Unknown conflict type #{conflict.type}"
          end
        end

        io << "\n"
      end

      # @rbs (IO io, Lrama::State state) -> void
      def report_shifts(io, state)
        shifts = state.term_transitions.reject(&:not_selected).map do |shift|
          [shift.next_sym, shift.to_state.id]
        end

        return if shifts.empty?

        # @type var next_syms: Array[Lrama::Grammar::Symbol]
        next_syms =  shifts.map(&:first)
        max_len = next_syms.map(&:display_name).map(&:length).max
        shifts.each do |term, state_id|
          # @type var term: Lrama::Grammar::Symbol
          io << "    #{term.display_name.ljust(max_len)}  shift, and go to state #{state_id}\n"
        end

        io << "\n"
      end

      # @rbs (IO io, Lrama::State state) -> void
      def report_nonassoc_errors(io, state)
        error_symbols = state.resolved_conflicts.select { |resolved| resolved.which == :error }.map { |error| error.symbol.display_name }

        return if error_symbols.empty?

        max_len = error_symbols.map(&:length).max
        error_symbols.each do |name|
          io << "    #{name.ljust(max_len)}  error (nonassociative)\n"
        end

        io << "\n"
      end

      # @rbs (IO io, Lrama::State state) -> void
      def report_reduces(io, state)
        reduce_pairs = [] #: Array[[Lrama::Grammar::Symbol, Lrama::State::Action::Reduce]]

        state.non_default_reduces.each do |reduce|
          reduce.look_ahead&.each do |term|
            reduce_pairs << [term, reduce]
          end
        end

        return if reduce_pairs.empty? && !state.default_reduction_rule

        max_len = [
          reduce_pairs.map(&:first).map(&:display_name).map(&:length).max || 0,
          state.default_reduction_rule ? "$default".length : 0
        ].max

        reduce_pairs.sort_by { |term, _| term.number }.each do |term, reduce|
          rule = reduce.item.rule
          io << "    #{term.display_name.ljust(max_len)}  reduce using rule #{rule.id} (#{rule.lhs.display_name})\n"
        end

        if (r = state.default_reduction_rule)
          s = "$default".ljust(max_len)

          if r.initial_rule?
            io << "    #{s}  accept\n"
          else
            io << "    #{s}  reduce using rule #{r.id} (#{r.lhs.display_name})\n"
          end
        end

        io << "\n"
      end

      # @rbs (IO io, Lrama::State state) -> void
      def report_nterm_transitions(io, state)
        goto_transitions = state.nterm_transitions.map do |goto|
          [goto.next_sym, goto.to_state.id]
        end.uniq.sort_by do |nterm, _|
          # @type var nterm: Lrama::Grammar::Symbol
          nterm.number
        end

        return if goto_transitions.empty?

        max_len = goto_transitions.map(&:first).map do |nterm|
          # @type var nterm: Lrama::Grammar::Symbol
          nterm.id.s_value.length
        end.max
        goto_transitions.each do |nterm, state_id|
          # @type var nterm: Lrama::Grammar::Symbol
          io << "    #{nterm.id.s_value.ljust(max_len)}  go to state #{state_id}\n"
        end

        io << "\n"
      end

      # @rbs (IO io, Lrama::State state) -> void
      def report_conflict_resolutions(io, state)
        return if state.resolved_conflicts.empty?

        state.resolved_conflicts.each do |resolved|
          io << "    #{resolved.report_message}\n"
        end

        io << "\n"
      end

      # @rbs (IO io, Lrama::State state, Lrama::Counterexamples cex) -> void
      def report_counterexamples(io, state, cex)
        examples = cex.compute(state)

        examples.each do |example|
          is_shift_reduce = example.type == :shift_reduce
          label0 = is_shift_reduce ? "shift/reduce" : "reduce/reduce"
          label1 = is_shift_reduce ? "Shift derivation" : "First Reduce derivation"
          label2 = is_shift_reduce ? "Reduce derivation" : "Second Reduce derivation"

          io << "    #{label0} conflict on token #{example.conflict_symbol.id.s_value}:\n"
          io << "        #{example.path1_item}\n"
          io << "        #{example.path2_item}\n"
          io << "      #{label1}\n"

          example.derivations1.render_strings_for_report.each do |str|
            io << "        #{str}\n"
          end

          io << "      #{label2}\n"

          example.derivations2.render_strings_for_report.each do |str|
            io << "        #{str}\n"
          end
        end
      end

      # @rbs (IO io, Lrama::State state, Lrama::States states) -> void
      def report_verbose_info(io, state, states)
        report_direct_read_sets(io, state, states)
        report_reads_relation(io, state, states)
        report_read_sets(io, state, states)
        report_includes_relation(io, state, states)
        report_lookback_relation(io, state, states)
        report_follow_sets(io, state, states)
        report_look_ahead_sets(io, state, states)
      end

      # @rbs (IO io, Lrama::State state, Lrama::States states) -> void
      def report_direct_read_sets(io, state, states)
        io << "  [Direct Read sets]\n"
        direct_read_sets = states.direct_read_sets

        states.nterms.each do |nterm|
          terms = direct_read_sets[[state.id, nterm.token_id]]
          next unless terms && !terms.empty?

          str = terms.map { |sym| sym.id.s_value }.join(", ")
          io << "    read #{nterm.id.s_value}  shift #{str}\n"
        end

        io << "\n"
      end

      # @rbs (IO io, Lrama::State state, Lrama::States states) -> void
      def report_reads_relation(io, state, states)
        io << "  [Reads Relation]\n"

        states.nterms.each do |nterm|
          relations = states.reads_relation[[state.id, nterm.token_id]]
          next unless relations

          relations.each do |state_id2, nterm_id2|
            n = states.nterms.find { |n| n.token_id == nterm_id2 }
            io << "    (State #{state_id2}, #{n&.id&.s_value})\n"
          end
        end

        io << "\n"
      end

      # @rbs (IO io, Lrama::State state, Lrama::States states) -> void
      def report_read_sets(io, state, states)
        io << "  [Read sets]\n"
        read_sets = states.read_sets

        states.nterms.each do |nterm|
          terms = read_sets[[state.id, nterm.token_id]]
          next unless terms && !terms.empty?

          terms.each do |sym|
            io << "    #{sym.id.s_value}\n"
          end
        end

        io << "\n"
      end

      # @rbs (IO io, Lrama::State state, Lrama::States states) -> void
      def report_includes_relation(io, state, states)
        io << "  [Includes Relation]\n"

        states.nterms.each do |nterm|
          relations = states.includes_relation[[state.id, nterm.token_id]]
          next unless relations

          relations.each do |state_id2, nterm_id2|
            n = states.nterms.find { |n| n.token_id == nterm_id2 }
            io << "    (State #{state.id}, #{nterm.id.s_value}) -> (State #{state_id2}, #{n&.id&.s_value})\n"
          end
        end

        io << "\n"
      end

      # @rbs (IO io, Lrama::State state, Lrama::States states) -> void
      def report_lookback_relation(io, state, states)
        io << "  [Lookback Relation]\n"

        states.rules.each do |rule|
          relations = states.lookback_relation[[state.id, rule.id]]
          next unless relations

          relations.each do |state_id2, nterm_id2|
            n = states.nterms.find { |n| n.token_id == nterm_id2 }
            io << "    (Rule: #{rule.display_name}) -> (State #{state_id2}, #{n&.id&.s_value})\n"
          end
        end

        io << "\n"
      end

      # @rbs (IO io, Lrama::State state, Lrama::States states) -> void
      def report_follow_sets(io, state, states)
        io << "  [Follow sets]\n"
        follow_sets = states.follow_sets

        states.nterms.each do |nterm|
          terms = follow_sets[[state.id, nterm.token_id]]
          next unless terms

          terms.each do |sym|
            io << "    #{nterm.id.s_value} -> #{sym.id.s_value}\n"
          end
        end

        io << "\n"
      end

      # @rbs (IO io, Lrama::State state, Lrama::States states) -> void
      def report_look_ahead_sets(io, state, states)
        io << "  [Look-Ahead Sets]\n"
        look_ahead_rules = [] #: Array[[Lrama::Grammar::Rule, Array[Lrama::Grammar::Symbol]]]

        states.rules.each do |rule|
          syms = states.la[[state.id, rule.id]]
          next unless syms

          look_ahead_rules << [rule, syms]
        end

        return if look_ahead_rules.empty?

        max_len = look_ahead_rules.flat_map { |_, syms| syms.map { |s| s.id.s_value.length } }.max

        look_ahead_rules.each do |rule, syms|
          syms.each do |sym|
            io << "    #{sym.id.s_value.ljust(max_len)}  reduce using rule #{rule.id} (#{rule.lhs.id.s_value})\n"
          end
        end

        io << "\n"
      end
    end
  end
end
