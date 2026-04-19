# rbs_inline: enabled
# frozen_string_literal: true

require "forwardable"
require "set"
require_relative "lexer_context_classifier"
require_relative "tracer/duration"
require_relative "state/item"

module Lrama
  # States is passed to a template file
  #
  # "Efficient Computation of LALR(1) Look-Ahead Sets"
  #   https://dl.acm.org/doi/pdf/10.1145/69622.357187
  class States
    # TODO: rbs-inline 0.11.0 doesn't support instance variables.
    #       Move these type declarations above instance variable definitions, once it's supported.
    #       see: https://github.com/soutaro/rbs-inline/pull/149
    #
    # @rbs!
    #   type state_id = Integer
    #   type rule_id = Integer
    #
    #   include Grammar::_DelegatedMethods
    #
    #   @grammar: Grammar
    #   @tracer: Tracer
    #   @states: Array[State]
    #   @direct_read_sets: Hash[State::Action::Goto, Bitmap::bitmap]
    #   @reads_relation: Hash[State::Action::Goto, Array[State::Action::Goto]]
    #   @read_sets: Hash[State::Action::Goto, Bitmap::bitmap]
    #   @includes_relation: Hash[State::Action::Goto, Array[State::Action::Goto]]
    #   @lookback_relation: Hash[state_id, Hash[rule_id, Array[State::Action::Goto]]]
    #   @follow_sets: Hash[State::Action::Goto, Bitmap::bitmap]
    #   @la: Hash[state_id, Hash[rule_id, Bitmap::bitmap]]

    extend Forwardable
    include Lrama::Tracer::Duration

    def_delegators "@grammar", :symbols, :terms, :nterms, :rules, :precedences,
      :accept_symbol, :eof_symbol, :undef_symbol, :find_symbol_by_s_value!, :ielr_defined?, :pslr_defined?,
      :token_patterns, :lex_prec, :lex_tie, :pslr_max_states, :pslr_max_state_ratio

    attr_reader :states #: Array[State]
    attr_reader :reads_relation #: Hash[State::Action::Goto, Array[State::Action::Goto]]
    attr_reader :includes_relation #: Hash[State::Action::Goto, Array[State::Action::Goto]]
    attr_reader :lookback_relation #: Hash[state_id, Hash[rule_id, Array[State::Action::Goto]]]
    attr_reader :scanner_fsa #: ScannerFSA?
    attr_reader :length_precedences #: LengthPrecedences?
    attr_reader :scanner_accepts_table #: State::ScannerAccepts?
    attr_reader :pslr_inadequacies #: Array[State::PslrInadequacy]
    attr_reader :pslr_metrics #: Hash[Symbol, Integer | Float | nil]
    attr_reader :lexer_context_classifier #: LexerContextClassifier?
    attr_reader :lexical_tie_candidates #: Array[[String, String]]

    # @rbs (Grammar grammar, Tracer tracer) -> void
    def initialize(grammar, tracer)
      @grammar = grammar
      @tracer = tracer

      @states = []

      # `DR(p, A) = {t ∈ T | p -(A)-> r -(t)-> }`
      #   where p is state, A is nterm, t is term.
      #
      # `@direct_read_sets` is a hash whose
      # key is goto,
      # value is bitmap of term.
      @direct_read_sets = {}

      # Reads relation on nonterminal transitions (pair of state and nterm)
      # `(p, A) reads (r, C) iff p -(A)-> r -(C)-> and C =>* ε`
      #   where p, r are state, A, C are nterm.
      #
      # `@reads_relation` is a hash whose
      # key is goto,
      # value is array of goto.
      @reads_relation = {}

      # `Read(p, A) =s DR(p, A) ∪ ∪{Read(r, C) | (p, A) reads (r, C)}`
      #
      # `@read_sets` is a hash whose
      # key is goto,
      # value is bitmap of term.
      @read_sets = {}

      # `(p, A) includes (p', B) iff B -> βAγ, γ =>* ε, p' -(β)-> p`
      #   where p, p' are state, A, B are nterm, β, γ is sequence of symbol.
      #
      # `@includes_relation` is a hash whose
      # key is goto,
      # value is array of goto.
      @includes_relation = {}

      # `(q, A -> ω) lookback (p, A) iff p -(ω)-> q`
      #   where p, q are state, A -> ω is rule, A is nterm, ω is sequence of symbol.
      #
      # `@lookback_relation` is a two-stage hash whose
      # first key is state_id,
      # second key is rule_id,
      # value is array of goto.
      @lookback_relation = {}

      # `Follow(p, A) =s Read(p, A) ∪ ∪{Follow(p', B) | (p, A) includes (p', B)}`
      #
      # `@follow_sets` is a hash whose
      # key is goto,
      # value is bitmap of term.
      @follow_sets = {}

      # `LA(q, A -> ω) = ∪{Follow(p, A) | (q, A -> ω) lookback (p, A)`
      #
      # `@la` is a two-stage hash whose
      # first key is state_id,
      # second key is rule_id,
      # value is bitmap of term.
      @la = {}
      @pslr_inadequacies = []
      @lexical_tie_candidates = []
      @pslr_metrics = {
        base_states_count: nil,
        total_states_count: nil,
        split_state_count: 0,
        growth_count: 0,
        growth_ratio: nil,
        token_pattern_count: 0,
        scanner_fsa_state_count: 0,
        inadequacies_count: 0
      }
    end

    # @rbs () -> void
    def compute
      report_duration(:compute_lr0_states) { compute_lr0_states }

      # Look Ahead Sets
      report_duration(:compute_look_ahead_sets) { compute_look_ahead_sets }

      # Conflicts
      report_duration(:compute_conflicts) { compute_conflicts(:lalr) }

      report_duration(:compute_default_reduction) { compute_default_reduction }
    end

    # @rbs () -> void
    def compute_ielr
      # Preparation
      report_duration(:clear_conflicts) { clear_conflicts }
      # Phase 1
      report_duration(:compute_predecessors) { compute_predecessors }
      report_duration(:compute_follow_kernel_items) { compute_follow_kernel_items }
      report_duration(:compute_always_follows) { compute_always_follows }
      report_duration(:compute_goto_follows) { compute_goto_follows }
      # Phase 2
      report_duration(:compute_inadequacy_annotations) { compute_inadequacy_annotations }
      # Phase 3
      report_duration(:split_states) { split_states }
      # Phase 4
      report_duration(:clear_look_ahead_sets) { clear_look_ahead_sets }
      report_duration(:compute_look_ahead_sets) { compute_look_ahead_sets }
      # Phase 5
      report_duration(:compute_conflicts) { compute_conflicts(:ielr) }
      report_duration(:compute_default_reduction) { compute_default_reduction }
    end

    # Compute PSLR(1) states
    # Based on Section 3.4 of the PSLR dissertation
    # @rbs () -> void
    def compute_pslr
      capture_pslr_metrics_before_split
      # Preparation
      report_duration(:clear_conflicts) { clear_conflicts }
      # Phase 1
      report_duration(:compute_predecessors) { compute_predecessors }
      report_duration(:compute_follow_kernel_items) { compute_follow_kernel_items }
      report_duration(:compute_always_follows) { compute_always_follows }
      report_duration(:compute_goto_follows) { compute_goto_follows }
      # Phase 2
      report_duration(:build_scanner_fsa) { build_scanner_fsa }
      report_duration(:build_length_precedences) { build_length_precedences }
      report_duration(:compute_inadequacy_annotations) { compute_inadequacy_annotations }
      # Phase 3a: PSLR split (Scanner FSA-based)
      @pslr_split_enabled = true
      report_duration(:split_states) { split_states }
      @pslr_split_enabled = false
      # Phase 3b: Lexer context classification + context-based split
      report_duration(:classify_lexer_contexts) { classify_lexer_contexts }
      report_duration(:split_states_by_context) { split_states_by_context }
      # Phase 4
      report_duration(:clear_look_ahead_sets) { clear_look_ahead_sets }
      report_duration(:compute_look_ahead_sets) { compute_look_ahead_sets }
      # Phase 5
      report_duration(:compute_conflicts) { compute_conflicts(:ielr) }
      report_duration(:compute_default_reduction) { compute_default_reduction }
      report_duration(:build_scanner_accepts) { build_scanner_accepts }
      report_duration(:handle_pslr_inadequacies) { handle_pslr_inadequacies }
      # Phase 6: Re-classify after all splits
      report_duration(:classify_lexer_contexts) { classify_lexer_contexts }
      finalize_pslr_metrics
    end

    # @rbs () -> Integer
    def states_count
      @states.count
    end

    # @rbs () -> Hash[State::Action::Goto, Array[Grammar::Symbol]]
    def direct_read_sets
      @_direct_read_sets ||= @direct_read_sets.transform_values do |v|
        bitmap_to_terms(v)
      end
    end

    # @rbs () -> Hash[State::Action::Goto, Array[Grammar::Symbol]]
    def read_sets
      @_read_sets ||= @read_sets.transform_values do |v|
        bitmap_to_terms(v)
      end
    end

    # @rbs () -> Hash[State::Action::Goto, Array[Grammar::Symbol]]
    def follow_sets
      @_follow_sets ||= @follow_sets.transform_values do |v|
        bitmap_to_terms(v)
      end
    end

    # @rbs () -> Hash[state_id, Hash[rule_id, Array[Grammar::Symbol]]]
    def la
      @_la ||= @la.transform_values do |second_hash|
        second_hash.transform_values do |v|
          bitmap_to_terms(v)
        end
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
      validate_pslr_state_growth!(logger)
      validate_pslr_scanner_conflicts!(logger)
      validate_pslr_inadequacies!(logger)
    end

    # Classify each state's lexer context based on kernel items.
    #
    # For each state, analyzes the kernel items to determine what lexer
    # context (BEG, CMDARG, ARG, END, ENDFN, MID, DOT) the state belongs to.
    # When a state has kernel items from multiple contexts, the context is
    # set to the bitwise OR of all contexts (mixed context).
    #
    # @rbs () -> void
    def classify_lexer_contexts
      return if @grammar.lexer_contexts.empty?

      @lexer_context_classifier = LexerContextClassifier.new(
        @grammar.lexer_contexts,
        @grammar.parameterized_expansion_args
      )

      @states.each do |state|
        groups = @lexer_context_classifier.classify(state)

        # Combine all contexts into a single bitmask
        combined = 0
        groups.each_key do |ctx|
          combined |= ctx if ctx > 0
        end

        state.lexer_context = combined
      end
    end

    # Return the lexer context table as an array of context values,
    # one per parser state (indexed by state id).
    #
    # @rbs () -> Array[Integer]
    def lexer_context_table
      @states.map { |state| state.lexer_context || 0 }
    end

    # Check if lexer context classification has been performed.
    #
    # @rbs () -> bool
    def lexer_context_enabled?
      pslr_defined? && @lexer_context_classifier != nil
    end

    def compute_la_sources_for_conflicted_states
      reflexive = {}
      reachable_parser_states.each do |state|
        state.nterm_transitions.each do |goto|
          reflexive[goto] = [goto]
        end
      end

      # compute_read_sets
      read_sets = Digraph.new(nterm_transitions, @reads_relation, reflexive).compute
      # compute_follow_sets
      follow_sets = Digraph.new(nterm_transitions, @includes_relation, read_sets).compute

      @states.select(&:has_conflicts?).each do |state|
        lookback_relation_on_state = @lookback_relation[state.id]
        next unless lookback_relation_on_state
        rules.each do |rule|
          ary = lookback_relation_on_state[rule.id]
          next unless ary

          sources = {}

          ary.each do |goto|
            source = follow_sets[goto]

            next unless source

            source.each do |goto2|
              tokens = direct_read_sets[goto2]
              tokens.each do |token|
                sources[token] ||= []
                sources[token] |= [goto2]
              end
            end
          end

          state.set_look_ahead_sources(rule, sources)
        end
      end
    end

    private

    # @rbs (Grammar::Symbol accessing_symbol, Array[State::Item] kernels, Hash[Array[State::Item], State] states_created) -> [State, bool]
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
      queued = {}
      items = state.kernels.dup

      items.each do |item|
        queued[item.rule_id] = true if item.position == 0
      end

      while (item = items.shift) do
        if (sym = item.next_sym) && sym.nterm?
          @grammar.find_rules_by_symbol!(sym).each do |rule|
            next if queued[rule.id]
            i = State::Item.new(rule: rule, position: 0)
            closure << i
            items << i
            queued[i.rule_id] = true
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

      state, _ = create_state(symbols.first, [State::Item.new(rule: @grammar.rules.first, position: 0)], states_created)
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
          state.set_lane_items(next_sym, new_state)
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
    def compute_look_ahead_sets
      report_duration(:compute_direct_read_sets) { compute_direct_read_sets }
      report_duration(:compute_reads_relation) { compute_reads_relation }
      report_duration(:compute_read_sets) { compute_read_sets }
      report_duration(:compute_includes_relation) { compute_includes_relation }
      report_duration(:compute_lookback_relation) { compute_lookback_relation }
      report_duration(:compute_follow_sets) { compute_follow_sets }
      report_duration(:compute_la) { compute_la }
    end

    # @rbs () -> void
    def compute_direct_read_sets
      @states.each do |state|
        state.nterm_transitions.each do |goto|
          ary = goto.to_state.term_transitions.map do |shift|
            shift.next_sym.number
          end

          @direct_read_sets[goto] = Bitmap.from_array(ary)
        end
      end
    end

    # @rbs () -> void
    def compute_reads_relation
      @states.each do |state|
        state.nterm_transitions.each do |goto|
          goto.to_state.nterm_transitions.each do |goto2|
            nterm2 = goto2.next_sym
            if nterm2.nullable
              @reads_relation[goto] ||= []
              @reads_relation[goto] << goto2
            end
          end
        end
      end
    end

    # @rbs () -> void
    def compute_read_sets
      @read_sets = Digraph.new(nterm_transitions, @reads_relation, @direct_read_sets).compute
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
        state.nterm_transitions.each do |goto|
          nterm = goto.next_sym
          @grammar.find_rules_by_symbol!(nterm).each do |rule|
            i = rule.rhs.count - 1

            while (i > -1) do
              sym = rule.rhs[i]

              break if sym.term?
              state2 = transition(state, rule.rhs[0...i])
              # p' = state, B = nterm, p = state2, A = sym
              key = state2.nterm_transitions.find do |goto2|
                goto2.next_sym.token_id == sym.token_id
              end || (raise "Goto by #{sym.name} on state #{state2.id} is not found")
              # TODO: need to omit if state == state2 ?
              @includes_relation[key] ||= []
              @includes_relation[key] << goto
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
        state.nterm_transitions.each do |goto|
          nterm = goto.next_sym
          @grammar.find_rules_by_symbol!(nterm).each do |rule|
            state2 = transition(state, rule.rhs)
            # p = state, A = nterm, q = state2, A -> ω = rule
            @lookback_relation[state2.id] ||= {}
            @lookback_relation[state2.id][rule.id] ||= []
            @lookback_relation[state2.id][rule.id] << goto
          end
        end
      end
    end

    # @rbs () -> void
    def compute_follow_sets
      @follow_sets = Digraph.new(nterm_transitions, @includes_relation, @read_sets).compute
    end

    # @rbs () -> void
    def compute_la
      @states.each do |state|
        lookback_relation_on_state = @lookback_relation[state.id]
        next unless lookback_relation_on_state
        rules.each do |rule|
          ary = lookback_relation_on_state[rule.id]
          next unless ary

          ary.each do |goto|
            # q = state, A -> ω = rule, p = state2, A = nterm
            follows = @follow_sets[goto]

            next if follows == 0

            @la[state.id] ||= {}
            @la[state.id][rule.id] ||= 0
            look_ahead = @la[state.id][rule.id] | follows
            @la[state.id][rule.id] |= look_ahead

            # No risk of conflict when
            # * the state only has single reduce
            # * the state only has nterm_transitions (GOTO)
            next if state.reduces.count == 1 && state.term_transitions.count == 0

            state.set_look_ahead(rule, bitmap_to_terms(look_ahead))
          end
        end
      end
    end

    # @rbs (Bitmap::bitmap bit) -> Array[Grammar::Symbol]
    def bitmap_to_terms(bit)
      ary = Bitmap.to_array(bit)
      ary.map do |i|
        @grammar.find_symbol_by_number!(i)
      end
    end

    # @rbs () -> void
    def compute_conflicts(lr_type)
      compute_shift_reduce_conflicts(lr_type)
      compute_reduce_reduce_conflicts
    end

    # @rbs () -> void
    def compute_shift_reduce_conflicts(lr_type)
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
              resolved_conflict = State::ResolvedConflict.new(state: state, symbol: sym, reduce: reduce, which: :reduce, resolved_by_precedence: false)
              state.resolved_conflicts << resolved_conflict
              shift.not_selected = true
              mark_precedences_used(lr_type, shift_prec, reduce_prec, resolved_conflict)
              next
            when shift_prec > reduce_prec
              # Shift is selected
              resolved_conflict = State::ResolvedConflict.new(state: state, symbol: sym, reduce: reduce, which: :shift, resolved_by_precedence: false)
              state.resolved_conflicts << resolved_conflict
              reduce.add_not_selected_symbol(sym)
              mark_precedences_used(lr_type, shift_prec, reduce_prec, resolved_conflict)
              next
            end

            # shift_prec == reduce_prec, then check associativity
            case sym.precedence.type
            when :precedence
              # Can not resolve the conflict
              #
              # %precedence only specifies precedence and not specify associativity
              # then a conflict is unresolved if precedence is same.
              state.conflicts << State::ShiftReduceConflict.new(symbols: [sym], shift: shift, reduce: reduce)
              next
            when :right
              # Shift is selected
              resolved_conflict = State::ResolvedConflict.new(state: state, symbol: sym, reduce: reduce, which: :shift, resolved_by_precedence: true)
              state.resolved_conflicts << resolved_conflict
              reduce.add_not_selected_symbol(sym)
              mark_precedences_used(lr_type, shift_prec, reduce_prec, resolved_conflict)
              next
            when :left
              # Reduce is selected
              resolved_conflict = State::ResolvedConflict.new(state: state, symbol: sym, reduce: reduce, which: :reduce, resolved_by_precedence: true)
              state.resolved_conflicts << resolved_conflict
              shift.not_selected = true
              mark_precedences_used(lr_type, shift_prec, reduce_prec, resolved_conflict)
              next
            when :nonassoc
              # The conflict is resolved
              #
              # %nonassoc creates "run-time" error by removing both shift and reduce from
              # the state. This makes the state to get syntax error if the conflicted token appears.
              # On the other hand, %precedence creates "compile-time" error by keeping both
              # shift and reduce on the state. This makes the state to be conflicted on the token.
              #
              # https://www.gnu.org/software/bison/manual/html_node/Using-Precedence.html
              resolved_conflict = State::ResolvedConflict.new(state: state, symbol: sym, reduce: reduce, which: :error, resolved_by_precedence: false)
              state.resolved_conflicts << resolved_conflict
              shift.not_selected = true
              reduce.add_not_selected_symbol(sym)
              mark_precedences_used(lr_type, shift_prec, reduce_prec, resolved_conflict)
            else
              raise "Unknown precedence type. #{sym}"
            end
          end
        end
      end
    end

    # @rbs (Grammar::Precedence shift_prec, Grammar::Precedence reduce_prec, State::ResolvedConflict resolved_conflict) -> void
    def mark_precedences_used(lr_type, shift_prec, reduce_prec, resolved_conflict)
      case lr_type
      when :lalr
        shift_prec.mark_used_by_lalr(resolved_conflict)
        reduce_prec.mark_used_by_lalr(resolved_conflict)
      when :ielr
        shift_prec.mark_used_by_ielr(resolved_conflict)
        reduce_prec.mark_used_by_ielr(resolved_conflict)
      end
    end

    # @rbs () -> void
    def compute_reduce_reduce_conflicts
      states.each do |state|
        state.reduces.combination(2) do |reduce1, reduce2|
          next if reduce1.look_ahead.nil? || reduce2.look_ahead.nil?

          intersection = reduce1.look_ahead & reduce2.look_ahead

          unless intersection.empty?
            state.conflicts << State::ReduceReduceConflict.new(symbols: intersection, reduce1: reduce1, reduce2: reduce2)
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
        next if state.term_transitions.map {|shift| shift.next_sym }.include?(@grammar.error_symbol)

        state.default_reduction_rule = state.reduces.map do |r|
          [r.rule, r.rule.id, (r.look_ahead || []).count]
        end.min_by do |rule, rule_id, count|
          [-count, rule_id]
        end.first
      end
    end

    # @rbs () -> void
    def clear_conflicts
      states.each(&:clear_conflicts)
    end

    # Definition 3.15 (Predecessors)
    #
    # @rbs () -> void
    def compute_predecessors
      @states.each do |state|
        state.transitions.each do |transition|
          transition.to_state.append_predecessor(state)
        end
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
        state = goto.from_state
        state.follow_kernel_items[goto] = state.kernels.map {|kernel|
          [kernel, Bitmap.to_bool_array(follow_kernel_items, state.kernels.count)]
        }.to_h
      end
    end

    # @rbs () -> Hash[State::Action::Goto, Array[State::Action::Goto]]
    def compute_goto_internal_relation
      relations = {}

      @states.each do |state|
        state.nterm_transitions.each do |goto|
          relations[goto] = state.internal_dependencies(goto)
        end
      end

      relations
    end

    # @rbs () -> Hash[State::Action::Goto, Bitmap::bitmap]
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
        goto.from_state.always_follows[goto] = bitmap_to_terms(always_follows_bitmap)
      end
    end

    # @rbs () -> Hash[State::Action::Goto, Array[State::Action::Goto]]
    def compute_goto_successor_or_internal_relation
      relations = {}

      @states.each do |state|
        state.nterm_transitions.each do |goto|
          relations[goto] = state.successor_dependencies(goto) + state.internal_dependencies(goto)
        end
      end

      relations
    end

    # @rbs () -> Hash[State::Action::Goto, Bitmap::bitmap]
    def compute_transition_bitmaps
      nterm_transitions.map {|goto|
        [goto, Bitmap.from_array(goto.to_state.term_transitions.map {|shift| shift.next_sym.number })]
      }.to_h
    end

    # Definition 3.24 (goto_follows, via always_follows)
    #
    # @rbs () -> void
    def compute_goto_follows
      set = nterm_transitions
      relation = compute_goto_internal_or_predecessor_dependencies
      base_function = compute_always_follows_bitmaps
      Digraph.new(set, relation, base_function).compute.each do |goto, goto_follows_bitmap|
        goto.from_state.goto_follows[goto] = bitmap_to_terms(goto_follows_bitmap)
      end
    end

    # @rbs () -> Hash[State::Action::Goto, Array[State::Action::Goto]]
    def compute_goto_internal_or_predecessor_dependencies
      relations = {}

      @states.each do |state|
        state.nterm_transitions.each do |goto|
          relations[goto] = state.internal_dependencies(goto) + state.predecessor_dependencies(goto)
        end
      end

      relations
    end

    # @rbs () -> Hash[State::Action::Goto, Bitmap::bitmap]
    def compute_always_follows_bitmaps
      nterm_transitions.map {|goto|
        [goto, Bitmap.from_array(goto.from_state.always_follows[goto].map(&:number))]
      }.to_h
    end

    # @rbs () -> void
    def split_states
      @states.each do |state|
        state.transitions.dup.each do |transition|
          compute_state(state, transition, transition.to_state)
        end
      end
    end

    # Split states where different predecessor paths lead to different
    # lexer contexts. This resolves LALR state merging that makes
    # BEG vs CMDARG (and other context pairs) indistinguishable.
    #
    # Algorithm:
    # 1. For each state, group incoming transitions by the lexer context
    #    that the predecessor would imply
    # 2. If a state has predecessors from multiple different contexts,
    #    split the state so each split has a unique context
    #
    # @rbs () -> void
    def split_states_by_context
      return unless @lexer_context_classifier

      # Iterate over a snapshot of states (new states may be added)
      states_snapshot = @states.dup

      states_snapshot.each do |state|
        # Skip start state and states with no context
        next if state.kernels.any?(&:start_item?)

        # Group predecessor transitions by the context they imply
        context_groups = compute_predecessor_context_groups(state)

        # Only split if there are multiple distinct non-zero contexts
        meaningful_groups = context_groups.reject { |ctx, _| ctx == 0 }
        next if meaningful_groups.size <= 1

        # The largest group keeps the original state
        primary_ctx, = meaningful_groups.max_by { |_, transitions| transitions.size }

        meaningful_groups.each do |ctx, transitions|
          next if ctx == primary_ctx

          # Create a new split state for this context group
          split = create_context_split_state(state)
          split.lexer_context = ctx

          # Update predecessor transitions to point to the new split state
          transitions.each do |pred_state, transition|
            pred_state.update_transition(transition, split)
          end
        end

        # Update the original state's context to the primary
        state.lexer_context = primary_ctx
      end
    end

    # For a given state, group its incoming transitions by the lexer context
    # that the predecessor state implies for this state.
    #
    # The implied context is determined by what symbol was used to reach
    # this state (the accessing symbol's context).
    #
    # @rbs (State state) -> Hash[Integer, Array[[State, State::Action::Shift | State::Action::Goto]]]
    def compute_predecessor_context_groups(state)
      groups = Hash.new { |h, k| h[k] = [] }

      state.predecessors.each do |pred|
        pred.transitions.each do |transition|
          next unless transition.to_state == state

          # The context is determined by the predecessor's context
          # combined with what we're transitioning on
          ctx = infer_transition_context(pred, transition)
          groups[ctx] << [pred, transition]
        end
      end

      groups
    end

    # Infer the lexer context that a transition implies for the target state.
    #
    # @rbs (State pred, State::Action::Shift | State::Action::Goto transition) -> Integer
    def infer_transition_context(pred, transition)
      sym = transition.next_sym
      if sym.term?
        @lexer_context_classifier.classify_terminal_context(sym)
      else
        @lexer_context_classifier.classify_nonterminal_context(sym)
      end
    end

    # Create a new split state that is an isocore copy of the given state.
    #
    # @rbs (State original) -> State
    def create_context_split_state(original)
      base = original.lalr_isocore || original
      new_state = State.new(@states.count, base.accessing_symbol, base.kernels)
      new_state.closure = base.closure
      new_state.compute_transitions_and_reduces

      # Copy transition targets from original
      original.transitions.each do |transition|
        new_state.set_items_to_state(transition.to_items, transition.to_state)
      end

      @states << new_state
      new_state.lalr_isocore = base
      base.ielr_isocores << new_state
      base.ielr_isocores.each do |st|
        st.ielr_isocores = base.ielr_isocores
      end

      new_state.lookaheads_recomputed = true
      new_state.item_lookahead_set = original.item_lookahead_set
      new_state.pslr_item_lookahead_set = original.pslr_item_lookahead_set

      new_state
    end

    # @rbs () -> void
    def capture_pslr_metrics_before_split
      @pslr_metrics = {
        base_states_count: @states.count,
        total_states_count: @states.count,
        split_state_count: 0,
        growth_count: 0,
        growth_ratio: 1.0,
        token_pattern_count: token_patterns.size,
        scanner_fsa_state_count: 0,
        inadequacies_count: 0
      }
    end

    # @rbs () -> void
    def compute_inadequacy_annotations
      @states.each do |state|
        state.annotate_manifestation
      end

      queue = @states.reject {|state| state.annotation_list.empty? }

      while (curr = queue.shift) do
        curr.predecessors.each do |pred|
          cache = pred.annotation_list.dup
          curr.annotate_predecessor(pred)
          queue << pred if cache != pred.annotation_list && !queue.include?(pred)
        end
      end
    end

    # @rbs (State state, State::lookahead_set filtered_lookaheads) -> void
    def merge_lookaheads(state, filtered_lookaheads)
      return if state.kernels.all? {|item| (filtered_lookaheads[item] - state.item_lookahead_set[item]).empty? }

      state.item_lookahead_set = state.item_lookahead_set.merge(filtered_lookaheads) {|_, v1, v2| v1 | v2 }
      state.transitions.each do |transition|
        next if transition.to_state.lookaheads_recomputed
        compute_state(state, transition, transition.to_state)
      end
    end

    # @rbs (State state, State::lookahead_set pslr_lookaheads) -> void
    def merge_pslr_lookaheads(state, pslr_lookaheads)
      state.pslr_item_lookahead_set ||= state.kernels.map {|kernel| [kernel, []] }.to_h
      return if state.kernels.all? {|item| (pslr_lookaheads[item] - state.pslr_item_lookahead_set[item]).empty? }

      state.pslr_item_lookahead_set = state.pslr_item_lookahead_set.merge(pslr_lookaheads) {|_, v1, v2| v1 | v2 }
    end

    # @rbs (State state, State::Action::Shift | State::Action::Goto transition, State next_state) -> void
    def compute_state(state, transition, next_state)
      propagating_lookaheads = state.propagate_lookaheads(next_state)
      pslr_lookaheads =
        if @pslr_split_enabled
          state.propagate_lookaheads_without_filter(next_state)
        else
          propagating_lookaheads
        end

      s = next_state.ielr_isocores.find {|st| compatible_split_state?(st, propagating_lookaheads, pslr_lookaheads) }

      if s.nil?
        s = next_state.lalr_isocore
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
        new_state.item_lookahead_set = pslr_lookaheads
        new_state.pslr_item_lookahead_set = pslr_lookaheads
        state.update_transition(transition, new_state)
      elsif(!s.lookaheads_recomputed)
        s.lookaheads_recomputed = true
        s.item_lookahead_set = pslr_lookaheads
        s.pslr_item_lookahead_set = pslr_lookaheads
      else
        merge_pslr_lookaheads(s, pslr_lookaheads) if @pslr_split_enabled
        merge_lookaheads(s, propagating_lookaheads)
        state.update_transition(transition, s) if state.items_to_state[transition.to_items].id != s.id
      end
    end

    # @rbs (State state, State::lookahead_set filtered_lookaheads, ?State::lookahead_set pslr_lookaheads) -> bool
    def compatible_split_state?(state, filtered_lookaheads, pslr_lookaheads = nil)
      return false unless state.is_compatible?(filtered_lookaheads)
      return true unless @pslr_split_enabled && @scanner_fsa

      pslr_lookaheads ||= filtered_lookaheads

      existing_acc = acceptable_tokens_for_pslr(state)
      candidate_acc = acceptable_tokens_for_pslr(state, pslr_lookaheads)
      pslr_compatible_accept_sets?(existing_acc, candidate_acc)
    end

    # @rbs (State state, ?State::lookahead_set filtered_lookaheads) -> Array[[Integer, String?]]
    def pslr_state_signature(state, filtered_lookaheads = nil)
      return [] unless @scanner_fsa

      acc_sp = acceptable_tokens_for_pslr(state, filtered_lookaheads)
      table, conflicts = State::ScannerAccepts.compute_for_acceptable_tokens(
        @scanner_fsa,
        lex_prec,
        @length_precedences || LengthPrecedences.new(lex_prec),
        acc_sp
      )

      signature = @scanner_fsa.states.each_with_object([]) do |fsa_state, result|
        next unless fsa_state.accepting?

        result << [fsa_state.id, table[fsa_state.id]&.name]
      end

      conflicts.each do |conflict|
        signature << [
          :unresolved,
          conflict.scanner_state_id,
          conflict.shorter_tokens,
          conflict.selected_shorter_token,
          conflict.current_tokens
        ]
      end

      signature
    end

    # @rbs (Set[String] left_acc, Set[String] right_acc) -> bool
    def pslr_compatible_accept_sets?(left_acc, right_acc)
      return true unless @scanner_fsa

      @pslr_compatibility_checker ||= State::ScannerAccepts::CompatibilityChecker.new(
        @scanner_fsa,
        lex_prec,
        @length_precedences || LengthPrecedences.new(lex_prec)
      )
      @pslr_compatibility_checker.compatible?(left_acc, right_acc)
    end

    # @rbs (State state, ?State::lookahead_set filtered_lookaheads, ?expand_ties: bool, ?include_layout: bool) -> Set[String]
    def acceptable_tokens_for_pslr(state, filtered_lookaheads = nil, expand_ties: true, include_layout: true)
      tokens = Set.new
      kernel_reduce_items = state.kernels.select(&:end_of_rule?).to_set

      state.term_transitions.each do |shift|
        next_sym = shift.next_sym
        tokens << next_sym.id.s_value if next_sym.term?
      end

      state.reduces.each do |reduce|
        look_ahead =
          if filtered_lookaheads && kernel_reduce_items.include?(reduce.item)
            filtered_lookaheads[reduce.item] || []
          else
            state.acceptable_pslr_reduce_lookahead(reduce)
          end

        look_ahead.each do |la|
          tokens << la.id.s_value
        end
      end

      tokens = @grammar.expand_lexical_ties(tokens) if expand_ties
      tokens | layout_token_names_for_pslr(include_layout: include_layout)
    end

    # @rbs (?include_layout: bool) -> Set[String]
    def layout_token_names_for_pslr(include_layout: true)
      return Set.new unless include_layout

      @grammar.layout_token_names
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

    # @rbs () -> void
    def clear_look_ahead_sets
      @direct_read_sets.clear
      @reads_relation.clear
      @read_sets.clear
      @includes_relation.clear
      @lookback_relation.clear
      @follow_sets.clear
      @la.clear

      @_direct_read_sets = nil
      @_read_sets = nil
      @_follow_sets = nil
      @_la = nil
    end

    # Build Scanner FSA from token patterns
    # @rbs () -> void
    def build_scanner_fsa
      @grammar.synthesize_implicit_literal_token_patterns!
      @grammar.finalize_lexical_declarations!
      return if token_patterns.empty?

      @scanner_fsa = ScannerFSA.new(token_patterns)
      @grammar.finalize_lexical_ties!(@scanner_fsa)
      @pslr_compatibility_checker = nil
    end

    # Build length precedences table
    # @rbs () -> void
    def build_length_precedences
      @length_precedences = LengthPrecedences.new(lex_prec)
    end

    # Build scanner_accepts table
    # @rbs () -> void
    def build_scanner_accepts
      return unless @scanner_fsa

      collect_lexical_tie_candidates

      effective_lex_prec = lex_prec
      scoped_lex_precs = build_scoped_lex_precs

      @scanner_accepts_table = State::ScannerAccepts.new(
        reachable_parser_states,
        @scanner_fsa,
        effective_lex_prec,
        @length_precedences,
        lex_tie,
        layout_token_names: @grammar.layout_token_names,
        scoped_lex_precs: scoped_lex_precs
      )
      @scanner_accepts_table.build
    end

    # Build per-state scoped lex-prec lookup.
    # Returns a hash of parser_state_id -> LexPrec that includes
    # both global and scope-active rules.
    # @rbs () -> Hash[Integer, Grammar::LexPrec]
    def build_scoped_lex_precs
      return {} if @grammar.scoped_lex_declarations.empty?

      result = {}
      reachable_parser_states.each do |state|
        active_nterms = active_nterm_names_for(state)
        next if active_nterms.empty?

        has_active_scope = @grammar.scoped_lex_declarations.any? do |decl|
          active_nterms.include?(decl.scope_name)
        end
        next unless has_active_scope

        result[state.id] = @grammar.scoped_lex_prec_for(active_nterms)
      end

      result
    end

    # Collect the nonterminal names that are "active" in a parser state.
    # A nonterminal is active if it appears as the LHS of any item in the state's closure.
    # @rbs (State state) -> Array[String]
    def active_nterm_names_for(state)
      names = Set.new
      (state.kernels + state.closure).each do |item|
        names << item.rule.lhs.id.s_value if item.rule.lhs.nterm?
      end
      names.to_a
    end

    # Handle PSLR inadequacies
    # Detects and splits states where pseudo-scanner behavior differs
    # @rbs () -> void
    def handle_pslr_inadequacies
      return unless @scanner_fsa && @scanner_accepts_table

      @pslr_inadequacies = detect_pslr_inadequacies
      return if @pslr_inadequacies.empty?

      @tracer.warn("Detected #{@pslr_inadequacies.size} unresolved PSLR inadequacies") if @tracer.respond_to?(:warn)
    end

    # @rbs () -> void
    def finalize_pslr_metrics
      return unless pslr_defined?

      base_states_count = @pslr_metrics[:base_states_count] || @states.count
      total_states_count = @states.count

      @pslr_metrics = {
        base_states_count: base_states_count,
        total_states_count: total_states_count,
        split_state_count: @states.count(&:split_state?),
        growth_count: total_states_count - base_states_count,
        growth_ratio: base_states_count.zero? ? nil : total_states_count.to_f / base_states_count,
        token_pattern_count: token_patterns.size,
        scanner_fsa_state_count: @scanner_fsa ? @scanner_fsa.states.size : 0,
        inadequacies_count: @pslr_inadequacies.size
      }
    end

    # Detect PSLR inadequacies in isocore groups
    # @rbs () -> Array[State::PslrInadequacy]
    def detect_pslr_inadequacies
      inadequacies = []

      @states.each do |state|
        state.transitions.each do |transition|
          next_state = transition.to_state
          next unless next_state

          propagating_lookaheads = state.propagate_lookaheads_without_filter(next_state.lalr_isocore)
          expected_acc = acceptable_tokens_for_pslr(next_state, propagating_lookaheads)
          actual_acc = acceptable_tokens_for_pslr(next_state)

          next if pslr_compatible_accept_sets?(expected_acc, actual_acc)

          matching_state = next_state.ielr_isocores.find do |candidate|
            pslr_compatible_accept_sets?(acceptable_tokens_for_pslr(candidate), expected_acc)
          end

          inadequacies << State::PslrInadequacy.new(
            type: State::PslrInadequacy::PSLR_RELATIVE,
            state: next_state,
            conflicting_states: [matching_state, next_state].compact.uniq,
            details: {
              reason: "Transition reaches a state with an incompatible PSLR scanner profile",
              from_state_id: state.id,
              transition_symbol: transition.next_sym.id.s_value,
              expected_profile: pslr_state_signature(next_state, propagating_lookaheads),
              actual_profile: pslr_state_signature(next_state),
              matching_state_id: matching_state&.id
            }
          )
        end
      end

      inadequacies
    end

    # @rbs () -> void
    def collect_lexical_tie_candidates
      @lexical_tie_candidates = []
      return unless @scanner_fsa

      pairs = @scanner_fsa.pairwise_conflict_pairs
      return if pairs.empty?

      candidates = Set.new
      reachable_parser_states.each do |state|
        pre_tie_tokens = acceptable_tokens_for_pslr(state, nil, expand_ties: false, include_layout: false)
        pairs.each do |left, right|
          next unless pre_tie_tokens.include?(left) ^ pre_tie_tokens.include?(right)
          next if lex_tie.tied?(left, right)
          next if lex_tie.no_tie?(left, right)

          candidates << [left, right]
        end
      end

      @lexical_tie_candidates = candidates.to_a.sort
    end

    # @rbs () -> Array[State]
    def reachable_parser_states
      return [] if @states.empty?

      visited = Set.new
      stack = [@states.first]
      reachable = []

      until stack.empty?
        state = stack.pop
        next if visited.include?(state.id)

        visited << state.id
        reachable << state
        state.transitions.each do |transition|
          stack << transition.to_state if transition.to_state
        end
      end

      reachable.sort_by(&:id)
    end

    # @rbs (Logger logger) -> void
    def validate_pslr_inadequacies!(logger)
      return unless pslr_defined?
      return if @pslr_inadequacies.empty?

      @pslr_inadequacies.each do |inadequacy|
        logger.error(inadequacy.to_s)
      end

      exit false
    end

    # @rbs (Logger logger) -> void
    def validate_pslr_scanner_conflicts!(logger)
      return unless pslr_defined?
      return unless @scanner_accepts_table
      return unless @scanner_accepts_table.unresolved_conflicts?

      @scanner_accepts_table.conflicts.each do |conflict|
        logger.error(pslr_scanner_conflict_message(conflict))
      end

      exit false
    end

    # @rbs (State::ScannerAccepts::Conflict conflict) -> String
    def pslr_scanner_conflict_message(conflict)
      state = conflict.parser_state_id || "unknown"
      shorter = conflict.shorter_tokens.empty? ? "(none)" : conflict.shorter_tokens.join(", ")
      selected = conflict.selected_shorter_token || "(none)"
      current = conflict.current_tokens.empty? ? "(none)" : conflict.current_tokens.join(", ")

      "unresolved PSLR scanner conflict in state #{state}, scanner state #{conflict.scanner_state_id}: " \
        "shorter matches: #{shorter}; selected shorter token: #{selected}; " \
        "current matches: #{current}; add an explicit %lex-prec rule or adjust lexical ties"
    end

    # @rbs (Logger logger) -> void
    def validate_pslr_state_growth!(logger)
      return unless pslr_defined?

      errors = []
      base_states_count = @pslr_metrics[:base_states_count] || @states.count
      total_states_count = @pslr_metrics[:total_states_count] || @states.count
      split_state_count = @pslr_metrics[:split_state_count] || @states.count(&:split_state?)
      growth_ratio = @pslr_metrics[:growth_ratio] || 1.0

      if (limit = pslr_max_states) && limit < total_states_count
        errors << "PSLR state growth exceeded pslr.max-states=#{limit} (total=#{total_states_count}, base=#{base_states_count}, split=#{split_state_count})"
      end

      if (limit = pslr_max_state_ratio) && limit < growth_ratio
        errors << "PSLR state growth exceeded pslr.max-state-ratio=#{limit} (ratio=#{format('%.2f', growth_ratio)}x, total=#{total_states_count}, base=#{base_states_count})"
      end

      return if errors.empty?

      errors.each do |message|
        logger.error(message)
      end

      exit false
    end
  end
end
