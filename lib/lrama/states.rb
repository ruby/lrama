# rbs_inline: enabled
# frozen_string_literal: true

require "forwardable"
require_relative "tracer/duration"
require_relative "states/item"

module Lrama
  # States is passed to a template file
  #
  # "Efficient Computation of LALR(1) Look-Ahead Sets"
  #   https://dl.acm.org/doi/pdf/10.1145/69622.357187
  class States
    # TODO: rbs-inline 0.10.0 doesn't support instance variables.
    #       Move these type declarations above instance variable definitions, once it's supported.
    #
    # @rbs!
    #   type bitmap = Integer
    #   type state_id = Integer
    #   type nterm_id = Integer
    #   type rule_id = Integer
    #   type transition = [state_id, nterm_id]
    #   type reduce = [state_id, rule_id]
    #
    #   include Grammar::_DelegatedMethods
    #   extend Forwardable
    #   include Lrama::Tracer::Duration
    #
    #   @grammar: Grammar
    #   @tracer: Tracer
    #   @states: Array[State]
    #   @direct_read_sets: Hash[transition, bitmap]
    #   @reads_relation: Hash[transition, Array[transition]]
    #   @read_sets: Hash[transition, bitmap]
    #   @includes_relation: Hash[transition, Array[transition]]
    #   @lookback_relation: Hash[reduce, Array[transition]]
    #   @follow_sets: Hash[reduce, bitmap]
    #   @la: Hash[reduce, bitmap]

    extend Forwardable
    include Lrama::Tracer::Duration

    def_delegators "@grammar", :symbols, :terms, :nterms, :rules,
      :accept_symbol, :eof_symbol, :undef_symbol, :find_symbol_by_s_value!

    attr_reader :states #: Array[State]
    attr_reader :reads_relation #: Hash[transition, Array[transition]]
    attr_reader :includes_relation #: Hash[transition, Array[transition]]
    attr_reader :lookback_relation #: Hash[[state_id, rule_id], Array[transition]]

    # @rbs (Grammar grammar, Tracer tracer) -> void
    def initialize(grammar, tracer)
      @grammar = grammar
      @tracer = tracer

      @states = []

      # `DR(p, A) = {t ∈ T | p -(A)-> r -(t)-> }`
      #   where p is state, A is nterm, t is term.
      #
      # `@direct_read_sets` is a hash whose
      # key is [state.id, nterm.token_id],
      # value is bitmap of term.
      @direct_read_sets = {}

      # Reads relation on nonterminal transitions (pair of state and nterm)
      # `(p, A) reads (r, C) iff p -(A)-> r -(C)-> and C =>* ε`
      #   where p, r are state, A, C are nterm.
      #
      # `@reads_relation` is a hash whose
      # key is [state.id, nterm.token_id],
      # value is array of [state.id, nterm.token_id].
      @reads_relation = {}

      # `Read(p, A) =s DR(p, A) ∪ ∪{Read(r, C) | (p, A) reads (r, C)}`
      #
      # `@read_sets` is a hash whose
      # key is [state.id, nterm.token_id],
      # value is bitmap of term.
      @read_sets = {}

      # `(p, A) includes (p', B) iff B -> βAγ, γ =>* ε, p' -(β)-> p`
      #   where p, p' are state, A, B are nterm, β, γ is sequence of symbol.
      #
      # `@includes_relation` is a hash whose
      # key is [state.id, nterm.token_id],
      # value is array of [state.id, nterm.token_id].
      @includes_relation = {}

      # `(q, A -> ω) lookback (p, A) iff p -(ω)-> q`
      #   where p, q are state, A -> ω is rule, A is nterm, ω is sequence of symbol.
      #
      # `@lookback_relation` is a hash whose
      # key is [state.id, rule.id],
      # value is array of [state.id, nterm.token_id].
      @lookback_relation = {}

      # `Follow(p, A) =s Read(p, A) ∪ ∪{Follow(p', B) | (p, A) includes (p', B)}`
      #
      # `@follow_sets` is a hash whose
      # key is [state.id, rule.id],
      # value is bitmap of term.
      @follow_sets = {}

      # `LA(q, A -> ω) = ∪{Follow(p, A) | (q, A -> ω) lookback (p, A)`
      #
      # `@la` is a hash whose
      # key is [state.id, rule.id],
      # value is bitmap of term.
      @la = {}
    end

    # @rbs () -> void
    def compute
      # Look Ahead Sets
      report_duration(:compute_lr0_states) { compute_lr0_states }
      report_duration(:compute_direct_read_sets) { compute_direct_read_sets }
      report_duration(:compute_reads_relation) { compute_reads_relation }
      report_duration(:compute_read_sets) { compute_read_sets }
      report_duration(:compute_includes_relation) { compute_includes_relation }
      report_duration(:compute_lookback_relation) { compute_lookback_relation }
      report_duration(:compute_follow_sets) { compute_follow_sets }
      report_duration(:compute_look_ahead_sets) { compute_look_ahead_sets }

      # Conflicts
      report_duration(:compute_conflicts) { compute_conflicts }

      report_duration(:compute_default_reduction) { compute_default_reduction }
    end

    # @rbs () -> void
    def compute_ielr
      # Phase 1
      report_duration(:compute_follow_kernel_items) { compute_follow_kernel_items }
      report_duration(:compute_always_follows) { compute_always_follows }
      # Phase 3
      report_duration(:split_states) { split_states }
      # Phase 4
      report_duration(:compute_direct_read_sets) { compute_direct_read_sets }
      report_duration(:compute_reads_relation) { compute_reads_relation }
      report_duration(:compute_read_sets) { compute_read_sets }
      report_duration(:compute_includes_relation) { compute_includes_relation }
      report_duration(:compute_lookback_relation) { compute_lookback_relation }
      report_duration(:compute_follow_sets) { compute_follow_sets }
      report_duration(:compute_look_ahead_sets) { compute_look_ahead_sets }
      # Phase 5
      report_duration(:compute_conflicts) { compute_conflicts }
      report_duration(:compute_default_reduction) { compute_default_reduction }
    end

    # @rbs () -> Integer
    def states_count
      @states.count
    end

    # @rbs () -> Hash[transition, Array[Grammar::Symbol]]
    def direct_read_sets
      @direct_read_sets.transform_values do |v|
        bitmap_to_terms(v)
      end
    end

    # @rbs () -> Hash[transition, Array[Grammar::Symbol]]
    def read_sets
      @read_sets.transform_values do |v|
        bitmap_to_terms(v)
      end
    end

    # @rbs () -> Hash[reduce, Array[Grammar::Symbol]]
    def follow_sets
      @follow_sets.transform_values do |v|
        bitmap_to_terms(v)
      end
    end

    # @rbs () -> Hash[reduce, Array[Grammar::Symbol]]
    def la
      @la.transform_values do |v|
        bitmap_to_terms(v)
      end
    end

    # @rbs () -> Integer
    def sr_conflicts_count
      @sr_conflicts_count ||= @states.flat_map(&:sr_conflicts).count
    end

    # @rbs () -> Integer
    def rr_conflicts_count
      @rr_conflicts_count ||= @states.flat_map(&:rr_conflicts).count
    end

    # @rbs (Logger logger) -> void
    def validate!(logger)
      validate_conflicts_within_threshold!(logger)
    end

    private

    # @rbs (Grammar::Symbol accessing_symbol, Array[Item] kernels, Hash[Array[Item], State] states_created) -> [State, bool]
    def create_state(accessing_symbol, kernels, states_created)
      # A item can appear in some states,
      # so need to use `kernels` (not `kernels.first`) as a key.
      #
      # For example...
      #
      # %%
      # program: '+' strings_1
      #        | '-' strings_2
      #        ;
      #
      # strings_1: string_1
      #          ;
      #
      # strings_2: string_1
      #          | string_2
      #          ;
      #
      # string_1: string
      #         ;
      #
      # string_2: string '+'
      #         ;
      #
      # string: tSTRING
      #       ;
      # %%
      #
      # For these grammar, there are 2 states
      #
      # State A
      #    string_1: string •
      #
      # State B
      #    string_1: string •
      #    string_2: string • '+'
      #
      return [states_created[kernels], false] if states_created[kernels]

      state = State.new(@states.count, accessing_symbol, kernels)
      @states << state
      states_created[kernels] = state

      return [state, true]
    end

    # @rbs (State state) -> void
    def setup_state(state)
      # closure
      closure = []
      visited = {}
      queued = {}
      items = state.kernels.dup

      items.each do |item|
        queued[item] = true
      end

      while (item = items.shift) do
        visited[item] = true

        if (sym = item.next_sym) && sym.nterm?
          @grammar.find_rules_by_symbol!(sym).each do |rule|
            i = Item.new(rule: rule, position: 0)
            next if queued[i]
            closure << i
            items << i
            queued[i] = true
          end
        end
      end

      state.closure = closure.sort_by {|i| i.rule.id }

      # Trace
      @tracer.trace_closure(state)

      # shift & reduce
      state.compute_transitions_and_reduces
    end

    # @rbs (Array[State] states, State state) -> void
    def enqueue_state(states, state)
      # Trace
      @tracer.trace_state_list_append(@states.count, state)

      states << state
    end

    # @rbs () -> void
    def compute_lr0_states
      # State queue
      states = []
      states_created = {}

      state, _ = create_state(symbols.first, [Item.new(rule: @grammar.rules.first, position: 0)], states_created)
      enqueue_state(states, state)

      while (state = states.shift) do
        # Trace
        @tracer.trace_state(state)

        setup_state(state)

        # `State#transitions` can not be used here
        # because `items_to_state` of the `state` is not set yet.
        state._transitions.each do |next_sym, to_items|
          new_state, created = create_state(next_sym, to_items, states_created)
          state.set_items_to_state(to_items, new_state)
          enqueue_state(states, new_state) if created
        end
      end
    end

    # @rbs () -> Array[State::Action::Goto]
    def nterm_transitions
      a = []

      @states.each do |state|
        state.nterm_transitions.each do |goto|
          a << goto
        end
      end

      a
    end

    # @rbs () -> void
    def compute_direct_read_sets
      @states.each do |state|
        state.nterm_transitions.each do |shift|
          nterm = shift.next_sym

          ary = shift.to_state.term_transitions.map do |shift|
            shift.next_sym.number
          end

          key = [state.id, nterm.token_id] # @type var key: transition
          @direct_read_sets[key] = Bitmap.from_array(ary)
        end
      end
    end

    # @rbs () -> void
    def compute_reads_relation
      @states.each do |state|
        state.nterm_transitions.each do |shift|
          nterm = shift.next_sym
          shift.to_state.nterm_transitions.each do |shift2|
            nterm2 = shift2.next_sym
            if nterm2.nullable
              key = [state.id, nterm.token_id] # @type var key: transition
              @reads_relation[key] ||= []
              @reads_relation[key] << [shift.to_state.id, nterm2.token_id]
            end
          end
        end
      end
    end

    # @rbs () -> void
    def compute_read_sets
      sets = nterm_transitions.map do |goto|
        [goto.from_state.id, goto.next_sym.token_id]
      end

      @read_sets = Digraph.new(sets, @reads_relation, @direct_read_sets).compute
    end

    # Execute transition of state by symbols
    # then return final state.
    #
    # @rbs (State state, Array[Grammar::Symbol] symbols) -> State
    def transition(state, symbols)
      symbols.each do |sym|
        state = state.transition(sym)
      end

      state
    end

    # @rbs () -> void
    def compute_includes_relation
      @states.each do |state|
        state.nterm_transitions.each do |shift|
          nterm = shift.next_sym
          @grammar.find_rules_by_symbol!(nterm).each do |rule|
            i = rule.rhs.count - 1

            while (i > -1) do
              sym = rule.rhs[i]

              break if sym.term?
              state2 = transition(state, rule.rhs[0...i])
              # p' = state, B = nterm, p = state2, A = sym
              key = [state2.id, sym.token_id] # @type var key: transition
              # TODO: need to omit if state == state2 ?
              @includes_relation[key] ||= []
              @includes_relation[key] << [state.id, nterm.token_id]
              break unless sym.nullable
              i -= 1
            end
          end
        end
      end
    end

    # @rbs () -> void
    def compute_lookback_relation
      @states.each do |state|
        state.nterm_transitions.each do |shift|
          nterm = shift.next_sym
          @grammar.find_rules_by_symbol!(nterm).each do |rule|
            state2 = transition(state, rule.rhs)
            # p = state, A = nterm, q = state2, A -> ω = rule
            key = [state2.id, rule.id] # @type var key: reduce
            @lookback_relation[key] ||= []
            @lookback_relation[key] << [state.id, nterm.token_id]
          end
        end
      end
    end

    # @rbs () -> void
    def compute_follow_sets
      sets = nterm_transitions.map do |goto|
        [goto.from_state.id, goto.next_sym.token_id]
      end

      @follow_sets = Digraph.new(sets, @includes_relation, @read_sets).compute
    end

    # @rbs () -> void
    def compute_look_ahead_sets
      @states.each do |state|
        rules.each do |rule|
          ary = @lookback_relation[[state.id, rule.id]]
          next unless ary

          ary.each do |state2_id, nterm_token_id|
            # q = state, A -> ω = rule, p = state2, A = nterm
            follows = @follow_sets[[state2_id, nterm_token_id]]

            next if follows == 0

            key = [state.id, rule.id] # @type var key: reduce
            @la[key] ||= 0
            look_ahead = @la[key] | follows
            @la[key] |= look_ahead

            # No risk of conflict when
            # * the state only has single reduce
            # * the state only has nterm_transitions (GOTO)
            next if state.reduces.count == 1 && state.term_transitions.count == 0

            state.set_look_ahead(rule, bitmap_to_terms(look_ahead))
          end
        end
      end
    end

    # @rbs (bitmap bit) -> Array[Grammar::Symbol]
    def bitmap_to_terms(bit)
      ary = Bitmap.to_array(bit)
      ary.map do |i|
        @grammar.find_symbol_by_number!(i)
      end
    end

    # @rbs () -> void
    def compute_conflicts
      compute_shift_reduce_conflicts
      compute_reduce_reduce_conflicts
    end

    # @rbs () -> void
    def compute_shift_reduce_conflicts
      states.each do |state|
        state.term_transitions.each do |shift|
          state.reduces.each do |reduce|
            sym = shift.next_sym

            next unless reduce.look_ahead
            next unless reduce.look_ahead.include?(sym)

            # Shift/Reduce conflict
            shift_prec = sym.precedence
            reduce_prec = reduce.item.rule.precedence

            # Can resolve only when both have prec
            unless shift_prec && reduce_prec
              state.conflicts << State::ShiftReduceConflict.new(symbols: [sym], shift: shift, reduce: reduce)
              next
            end

            case
            when shift_prec < reduce_prec
              # Reduce is selected
              state.resolved_conflicts << State::ResolvedConflict.new(symbol: sym, reduce: reduce, which: :reduce)
              shift.not_selected = true
              next
            when shift_prec > reduce_prec
              # Shift is selected
              state.resolved_conflicts << State::ResolvedConflict.new(symbol: sym, reduce: reduce, which: :shift)
              reduce.add_not_selected_symbol(sym)
              next
            end

            # shift_prec == reduce_prec, then check associativity
            case sym.precedence.type
            when :precedence
              # %precedence only specifies precedence and not specify associativity
              # then a conflict is unresolved if precedence is same.
              state.conflicts << State::ShiftReduceConflict.new(symbols: [sym], shift: shift, reduce: reduce)
              next
            when :right
              # Shift is selected
              state.resolved_conflicts << State::ResolvedConflict.new(symbol: sym, reduce: reduce, which: :shift, same_prec: true)
              reduce.add_not_selected_symbol(sym)
              next
            when :left
              # Reduce is selected
              state.resolved_conflicts << State::ResolvedConflict.new(symbol: sym, reduce: reduce, which: :reduce, same_prec: true)
              shift.not_selected = true
              next
            when :nonassoc
              # Can not resolve
              #
              # nonassoc creates "run-time" error, precedence creates "compile-time" error.
              # Then omit both the shift and reduce.
              #
              # https://www.gnu.org/software/bison/manual/html_node/Using-Precedence.html
              state.resolved_conflicts << State::ResolvedConflict.new(symbol: sym, reduce: reduce, which: :error)
              shift.not_selected = true
              reduce.add_not_selected_symbol(sym)
            else
              raise "Unknown precedence type. #{sym}"
            end
          end
        end
      end
    end

    # @rbs () -> void
    def compute_reduce_reduce_conflicts
      states.each do |state|
        count = state.reduces.count

        (0...count).each do |i|
          reduce1 = state.reduces[i]
          next if reduce1.look_ahead.nil?

          ((i+1)...count).each do |j|
            reduce2 = state.reduces[j]
            next if reduce2.look_ahead.nil?

            intersection = reduce1.look_ahead & reduce2.look_ahead

            unless intersection.empty?
              state.conflicts << State::ReduceReduceConflict.new(symbols: intersection, reduce1: reduce1, reduce2: reduce2)
            end
          end
        end
      end
    end

    # @rbs () -> void
    def compute_default_reduction
      states.each do |state|
        next if state.reduces.empty?
        # Do not set, if conflict exist
        next unless state.conflicts.empty?
        # Do not set, if shift with `error` exists.
        next if state.transitions.map {|transition, _| transition.next_sym }.include?(@grammar.error_symbol)

        state.default_reduction_rule = state.reduces.map do |r|
          [r.rule, r.rule.id, (r.look_ahead || []).count]
        end.min_by do |rule, rule_id, count|
          [-count, rule_id]
        end.first
      end
    end

    # Definition 3.16 (follow_kernel_items)
    #
    # @rbs () -> void
    def compute_follow_kernel_items
      set = nterm_transitions
      relation = compute_goto_internal_relation
      base_function = compute_goto_bitmaps
      Digraph.new(set, relation, base_function).compute.each do |goto, follow_kernel_items|
        state, nterm = goto.from_state, goto.next_sym
        transition = state.nterm_transitions.find {|shift| shift.next_sym == nterm }
        state.follow_kernel_items[transition] = state.kernels.map.with_index {|kernel, i|
          [kernel, Bitmap.to_bool_array(follow_kernel_items, state.kernels.count)]
        }.to_h
      end
    end

    # @rbs () -> Hash[State::Action::Goto, Array[State::Action::Goto]]
    def compute_goto_internal_relation
      nterm_transitions.map {|goto1|
        related_gotos = nterm_transitions.select {|goto2| has_internal_relation?(goto1, goto2) }
        [goto1, related_gotos]
      }.to_h
    end

    # @rbs () -> Hash[State::Action::Goto, bitmap]
    def compute_goto_bitmaps
      nterm_transitions.map {|goto|
        bools = goto.from_state.kernels.map.with_index {|kernel, i| i if kernel.next_sym == goto.next_sym && kernel.symbols_after_transition.all?(&:nullable) }.compact
        [goto, Bitmap.from_array(bools)]
      }.to_h
    end

    # Definition 3.20 (always_follows, one closure)
    #
    # @rbs () -> void
    def compute_always_follows
      set = nterm_transitions
      relation = compute_goto_successor_or_internal_relation
      base_function = compute_transition_bitmaps
      Digraph.new(set, relation, base_function).compute.each do |goto, always_follows_bitmap|
        state, nterm = goto.from_state, goto.next_sym
        transition = state.nterm_transitions.find {|shift| shift.next_sym == nterm }
        state.always_follows[transition] = bitmap_to_terms(always_follows_bitmap)
      end
    end

    # @rbs () -> Hash[State::Action::Goto, Array[State::Action::Goto]]
    def compute_goto_successor_or_internal_relation
      nterm_transitions.map {|goto1|
        related_gotos = nterm_transitions.select {|goto2|
          has_internal_relation?(goto1, goto2) || has_successor_relation?(goto1, goto2)
        }
        [goto1, related_gotos]
      }.to_h
    end

    # @rbs () -> Hash[State::Action::Goto, bitmap]
    def compute_transition_bitmaps
      nterm_transitions.map {|goto|
        [goto, Bitmap.from_array(goto.to_state.transitions.map {|shift| shift.next_sym.number })]
      }.to_h
    end

    # Definition 3.8 (Goto Follows Internal Relation)
    #
    # @rbs (State::Action::Goto goto1, State::Action::Goto goto2) -> bool
    def has_internal_relation?(goto1, goto2)
      state1, sym1 = goto1.from_state, goto1.next_sym
      state2, sym2 = goto2.from_state, goto2.next_sym
      state1 == state2 && state1.items.any? {|item|
        item.next_sym == sym1 && item.lhs == sym2 && item.symbols_after_transition.all?(&:nullable)
      }
    end

    # Definition 3.5 (Goto Follows Successor Relation)
    #
    # @rbs (State::Action::Goto goto1, State::Action::Goto goto2) -> bool
    def has_successor_relation?(goto1, goto2)
      goto1.to_state == goto2.from_state && goto2.next_sym.nullable
    end

    # @rbs () -> void
    def split_states
      @states.each do |state|
        state.transitions.each do |shift|
          shift.to_state.append_predecessor(state)
        end
      end

      compute_inadequacy_annotations

      @states.each do |state|
        state.transitions.each do |shift|
          compute_state(state, shift, shift.to_state)
        end
      end
    end

    # @rbs () -> void
    def compute_inadequacy_annotations
      @states.each do |state|
        state.annotate_manifestation
      end

      @states.reverse.each do |state|
        queue = [state]
        while (curr = queue.shift) do
          curr.predecessors.each do |pred|
            cache = pred.annotation_list.dup
            pred.annotate_predecessor(curr)
            queue << pred if cache != pred.annotation_list
          end
        end
      end
    end

    # @rbs (State state, Hash[States::Item, Array[Grammar::Symbol]] filtered_lookaheads) -> void
    def merge_lookaheads(state, filtered_lookaheads)
      return if state.kernels.all? {|item| (filtered_lookaheads[item] - state.item_lookahead_set[item]).empty? }

      state.item_lookahead_set = state.item_lookahead_set.merge {|_, v1, v2| v1 | v2 }
      state.transitions.each do |transition|
        next if transition.to_state.lookaheads_recomputed
        compute_state(state, transition, transition.to_state)
      end
    end

    # @rbs (State state, State::Action::Shift | State::Action::Goto transition, State next_state) -> void
    def compute_state(state, transition, next_state)
      propagating_lookaheads = state.propagate_lookaheads(next_state)
      s = next_state.ielr_isocores.find {|st| st.is_compatible?(propagating_lookaheads) }

      if s.nil?
        s = next_state.ielr_isocores.last
        new_state = State.new(@states.count, s.accessing_symbol, s.kernels)
        new_state.closure = s.closure
        new_state.compute_transitions_and_reduces
        s.transitions.each do |transition|
          new_state.set_items_to_state(transition.to_items, transition.to_state)
        end
        @states << new_state
        new_state.lalr_isocore = s
        s.ielr_isocores << new_state
        s.ielr_isocores.each do |st|
          st.ielr_isocores = s.ielr_isocores
        end
        new_state.lookaheads_recomputed = true
        new_state.item_lookahead_set = propagating_lookaheads
        state.update_transition(transition, new_state)
        compute_follow_kernel_items
        compute_always_follows
      elsif(!s.lookaheads_recomputed)
        s.lookaheads_recomputed = true
        s.item_lookahead_set = propagating_lookaheads
      else
        state.update_transition(transition, s)
        merge_lookaheads(s, propagating_lookaheads)
      end
    end

    # @rbs (Logger logger) -> void
    def validate_conflicts_within_threshold!(logger)
      exit false unless conflicts_within_threshold?(logger)
    end

    # @rbs (Logger logger) -> bool
    def conflicts_within_threshold?(logger)
      return true unless @grammar.expect

      [sr_conflicts_within_threshold?(logger), rr_conflicts_within_threshold?(logger)].all?
    end

    # @rbs (Logger logger) -> bool
    def sr_conflicts_within_threshold?(logger)
      return true if @grammar.expect == sr_conflicts_count

      logger.error("shift/reduce conflicts: #{sr_conflicts_count} found, #{@grammar.expect} expected")
      false
    end

    # @rbs (Logger logger) -> bool
    def rr_conflicts_within_threshold?(logger, expected: 0)
      return true if expected == rr_conflicts_count

      logger.error("reduce/reduce conflicts: #{rr_conflicts_count} found, #{expected} expected")
      false
    end
  end
end
