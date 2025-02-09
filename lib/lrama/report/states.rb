# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Report
    class States
      # @rbs (itemsets: bool, lookaheads: bool, solved: bool, counterexamples: bool, verbose: bool, **untyped _) -> void
      def initialize(itemsets: false, lookaheads: false, solved: false, counterexamples: false, verbose: false, **_)
        @itemsets = itemsets
        @lookaheads = lookaheads
        @solved = solved
        @counterexamples = counterexamples
        @verbose = verbose
      end

      # @rbs (Lrama::States states, Lrama::Logger logger) -> void
      def report(states, logger)
        if @counterexamples
          cex = Counterexamples.new(states)
        end

        states.states.each do |state|
          # Report State
          logger.trace("State #{state.id}\n")

          # Report item
          last_lhs = nil
          list = @itemsets ? state.items : state.kernels
          list.sort_by {|i| [i.rule_id, i.position] }.each do |item|
            if item.empty_rule?
              r = "ε •"
            else
              r = item.rhs.map(&:display_name).insert(item.position, "•").join(" ")
            end
            if item.lhs == last_lhs
              l = " " * item.lhs.id.s_value.length + "|"
            else
              l = item.lhs.id.s_value + ":"
            end
            la = ""
            if @lookaheads && item.end_of_rule?
              reduce = state.find_reduce_by_item!(item)
              look_ahead = reduce.selected_look_ahead
              unless look_ahead.empty?
                la = "  [#{look_ahead.map(&:display_name).join(", ")}]"
              end
            end
            last_lhs = item.lhs

            logger.trace(sprintf("%5i %s %s%s", item.rule_id, l, r, la))
          end
          logger.line_break

          # Report shifts
          tmp = state.term_transitions.reject do |shift, _|
            shift.not_selected
          end.map do |shift, next_state|
            [shift.next_sym, next_state.id]
          end
          max_len = tmp.map(&:first).map(&:display_name).map(&:length).max
          tmp.each do |term, state_id|
            logger.trace("    #{term.display_name.ljust(max_len)}  shift, and go to state #{state_id}")
          end
          logger.line_break unless tmp.empty?

          # Report error caused by %nonassoc
          nl = false
          tmp = state.resolved_conflicts.select do |resolved|
            resolved.which == :error
          end.map do |error|
            error.symbol.display_name
          end
          max_len = tmp.map(&:length).max
          tmp.each do |name|
            nl = true
            logger.trace("    #{name.ljust(max_len)}  error (nonassociative)")
          end
          logger.line_break unless tmp.empty?

          # Report reduces
          nl = false
          max_len = state.non_default_reduces.flat_map(&:look_ahead).compact.map(&:display_name).map(&:length).max || 0
          max_len = [max_len, "$default".length].max if state.default_reduction_rule
          ary = [] #: Array[[Lrama::Grammar::Symbol, Lrama::State::Reduce]]

          state.non_default_reduces.each do |reduce|
            reduce.look_ahead.each do |term|
              ary << [term, reduce]
            end
          end

          ary.sort_by do |term, reduce|
            term.number
          end.each do |term, reduce|
            rule = reduce.item.rule
            logger.trace("    #{term.display_name.ljust(max_len)}  reduce using rule #{rule.id} (#{rule.lhs.display_name})")
            nl = true
          end

          if (r = state.default_reduction_rule)
            nl = true
            s = "$default".ljust(max_len)

            if r.initial_rule?
              logger.trace("    #{s}  accept")
            else
                logger.trace("    #{s}  reduce using rule #{r.id} (#{r.lhs.display_name})")
            end
          end
          logger.line_break if nl

          # Report nonterminal transitions
          tmp = [] #: Array[[Lrama::Grammar::Symbol, Integer]]
          max_len = 0
          state.nterm_transitions.each do |shift, next_state|
            nterm = shift.next_sym
            tmp << [nterm, next_state.id]
            max_len = [max_len, nterm.id.s_value.length].max
          end
          tmp.uniq!
          tmp.sort_by! do |nterm, state_id|
            nterm.number
          end
          tmp.each do |nterm, state_id|
            logger.trace("    #{nterm.id.s_value.ljust(max_len)}  go to state #{state_id}")
          end
          logger.line_break unless tmp.empty?

          if @solved
            # Report conflict resolutions
            state.resolved_conflicts.each do |resolved|
              logger.trace("    #{resolved.report_message}")
            end
            logger.line_break unless state.resolved_conflicts.empty?
          end

          if @counterexamples && state.has_conflicts?
            # Report counterexamples
            # @type var cex: Lrama::Counterexamples
            examples = cex.compute(state)
            examples.each do |example|
              label0 = example.type == :shift_reduce ? "shift/reduce" : "reduce/reduce"
              label1 = example.type == :shift_reduce ? "Shift derivation"  : "First Reduce derivation"
              label2 = example.type == :shift_reduce ? "Reduce derivation" : "Second Reduce derivation"

              logger.trace("    #{label0} conflict on token #{example.conflict_symbol.id.s_value}:")
              logger.trace("        #{example.path1_item}")
              logger.trace("        #{example.path2_item}")
              logger.trace("      #{label1}")
              example.derivations1.render_strings_for_report.each do |str|
                logger.trace("        #{str}")
              end
              logger.trace("      #{label2}")
              example.derivations2.render_strings_for_report.each do |str|
                logger.trace("        #{str}")
              end
            end
          end

          if @verbose
            # Report direct_read_sets
            logger.trace("  [Direct Read sets]")
            direct_read_sets = states.direct_read_sets
            states.nterms.each do |nterm|
              terms = direct_read_sets[[state.id, nterm.token_id]]
              next unless terms
              next if terms.empty?

              str = terms.map {|sym| sym.id.s_value }.join(", ")
              logger.trace("    read #{nterm.id.s_value}  shift #{str}")
            end
            logger.line_break

            # Report reads_relation
            logger.trace("  [Reads Relation]")
            states.nterms.each do |nterm|
              a = states.reads_relation[[state.id, nterm.token_id]]
              next unless a

              a.each do |state_id2, nterm_id2|
                n = states.nterms.find {|n| n.token_id == nterm_id2 }
                logger.trace("    (State #{state_id2}, #{n&.id&.s_value})")
              end
            end
            logger.line_break

            # Report read_sets
            logger.trace("  [Read sets]")
            read_sets = states.read_sets
            states.nterms.each do |nterm|
              terms = read_sets[[state.id, nterm.token_id]]
              next unless terms
              next if terms.empty?

              terms.each do |sym|
                logger.trace("    #{sym.id.s_value}")
              end
            end
            logger.line_break

            # Report includes_relation
            logger.trace("  [Includes Relation]")
            states.nterms.each do |nterm|
              a = states.includes_relation[[state.id, nterm.token_id]]
              next unless a

              a.each do |state_id2, nterm_id2|
                n = states.nterms.find {|n| n.token_id == nterm_id2 }
                logger.trace("    (State #{state.id}, #{nterm.id.s_value}) -> (State #{state_id2}, #{n&.id&.s_value})")
              end
            end
            logger.line_break

            # Report lookback_relation
            logger.trace("  [Lookback Relation]")
            states.rules.each do |rule|
              a = states.lookback_relation[[state.id, rule.id]]
              next unless a

              a.each do |state_id2, nterm_id2|
                n = states.nterms.find {|n| n.token_id == nterm_id2 }
                logger.trace("    (Rule: #{rule.display_name}) -> (State #{state_id2}, #{n&.id&.s_value})")
              end
            end
            logger.line_break

            # Report follow_sets
            logger.trace("  [Follow sets]")
            follow_sets = states.follow_sets
            states.nterms.each do |nterm|
              terms = follow_sets[[state.id, nterm.token_id]]

              next unless terms

              terms.each do |sym|
                logger.trace("    #{nterm.id.s_value} -> #{sym.id.s_value}")
              end
            end
            logger.line_break

            # Report LA
            logger.trace("  [Look-Ahead Sets]")
            tmp = [] #: Array[[Lrama::Grammar::Rule, Array[Lrama::Grammar::Symbol]]]
            max_len = 0
            states.rules.each do |rule|
              syms = states.la[[state.id, rule.id]]
              next unless syms

              tmp << [rule, syms]
              max_len = ([max_len] + syms.map {|s| s.id.s_value.length }).max
            end
            tmp.each do |rule, syms|
              syms.each do |sym|
                logger.trace("    #{sym.id.s_value.ljust(max_len)}  reduce using rule #{rule.id} (#{rule.lhs.id.s_value})")
              end
            end
            logger.line_break unless tmp.empty?
          end

          # End of Report State
          logger.line_break
        end
      end
    end
  end
end
