# rbs_inline: enabled
# frozen_string_literal: true

require_relative "state/action"
require_relative "state/inadequacy_annotation"
require_relative "state/item"
require_relative "state/reduce_reduce_conflict"
require_relative "state/resolved_conflict"
require_relative "state/shift_reduce_conflict"

module Lrama
  class State
    # TODO: rbs-inline 0.11.0 doesn't support instance variables.
    #       Move these type declarations above instance variable definitions, once it's supported.
    #       see: https://github.com/soutaro/rbs-inline/pull/149
    #
    # @rbs!
    #   type conflict = State::ShiftReduceConflict | State::ReduceReduceConflict
    #   type transition = Action::Shift | Action::Goto
    #   type lookahead_set = Hash[Item, Array[Grammar::Symbol]]
    #   type dominant_contributions = Hash[InadequacyAnnotation, Array[InadequacyAnnotation::action]?]
    #   type item_pair = [State, Item]
    #   type item_origins_cache = Hash[item_pair, Array[item_pair]]
    #
    #   @id: Integer
    #   @accessing_symbol: Grammar::Symbol
    #   @kernels: Array[Item]
    #   @items: Array[Item]
    #   @items_to_state: Hash[Array[Item], State]
    #   @conflicts: Array[conflict]
    #   @resolved_conflicts: Array[ResolvedConflict]
    #   @default_reduction_rule: Grammar::Rule?
    #   @closure: Array[Item]
    #   @nterm_transitions: Array[Action::Goto]
    #   @term_transitions: Array[Action::Shift]
    #   @transitions: Array[transition]
    #   @transitions_by_symbol_number: Hash[Integer, transition]
    #   @internal_dependencies: Hash[Action::Goto, Array[Action::Goto]]
    #   @successor_dependencies: Hash[Action::Goto, Array[Action::Goto]]
    #   @dominant_contributions: dominant_contributions?
    #   @predecessor_set: Hash[State, bool]?
    #   @item_index: Hash[[Grammar::Symbol, Integer?, Integer], Array[Item]]?
    #   @internal_dependency_symbols: Hash[Grammar::Symbol, Hash[Grammar::Symbol, bool]]?

    attr_reader :id #: Integer
    attr_reader :accessing_symbol #: Grammar::Symbol
    attr_reader :kernels #: Array[Item]
    attr_reader :conflicts #: Array[conflict]
    attr_reader :resolved_conflicts #: Array[ResolvedConflict]
    attr_reader :default_reduction_rule #: Grammar::Rule?
    attr_reader :closure #: Array[Item]
    attr_reader :items #: Array[Item]
    attr_reader :annotation_list #: Array[InadequacyAnnotation]
    attr_reader :predecessors #: Array[State]
    attr_reader :items_to_state #: Hash[Array[Item], State]
    attr_reader :lane_items #: Hash[State, Array[[Item, Item]]]

    attr_accessor :_transitions #: Array[[Grammar::Symbol, Array[Item]]]
    attr_accessor :reduces #: Array[Action::Reduce]
    attr_accessor :ielr_isocores #: Array[State]
    attr_accessor :lalr_isocore #: State
    attr_accessor :lookaheads_recomputed #: bool
    attr_accessor :follow_kernel_items #: Hash[Action::Goto, Hash[Item, bool]]
    attr_accessor :always_follows #: Hash[Action::Goto, Array[Grammar::Symbol]]
    attr_accessor :goto_follows #: Hash[Action::Goto, Array[Grammar::Symbol]]

    # @rbs (Integer id, Grammar::Symbol accessing_symbol, Array[Item] kernels) -> void
    def initialize(id, accessing_symbol, kernels)
      @id = id
      @accessing_symbol = accessing_symbol
      @kernels = kernels.freeze
      @items = @kernels
      # Manage relationships between items to state
      # to resolve next state
      @items_to_state = {}
      @conflicts = []
      @resolved_conflicts = []
      @default_reduction_rule = nil
      @predecessors = []
      @lalr_isocore = self
      @ielr_isocores = [self]
      @internal_dependencies = {}
      @successor_dependencies = {}
      @annotation_list = []
      @lookaheads_recomputed = false
      @follow_kernel_items = {}
      @always_follows = {}
      @goto_follows = {}
      @lhs_contributions = {}
      @lane_items = {}
    end

    # @rbs (State other) -> bool
    def ==(other)
      self.id == other.id
    end

    # @rbs (Array[Item] closure) -> void
    def closure=(closure)
      @closure = closure
      @items = @kernels + @closure
      @item_index = nil
      @internal_dependency_symbols = nil
      @internal_dependencies.clear
    end

    # @rbs () -> Array[Action::Reduce]
    def non_default_reduces
      reduces.reject do |reduce|
        reduce.rule == @default_reduction_rule
      end
    end

    # @rbs () -> void
    def compute_transitions_and_reduces
      _transitions = {}
      @_lane_items ||= {}
      reduces = []
      items.each do |item|
        # TODO: Consider what should be pushed
        if item.end_of_rule?
          reduces << Action::Reduce.new(item)
        else
          key = item.next_sym
          _transitions[key] ||= []
          @_lane_items[key] ||= []
          next_item = item.new_by_next_position
          _transitions[key] << next_item
          @_lane_items[key] << [item, next_item]
        end
      end

      # It seems Bison 3.8.2 iterates transitions order by symbol number
      transitions = _transitions.sort_by do |next_sym, to_items|
        next_sym.number
      end

      self._transitions = transitions.freeze
      self.reduces = reduces.freeze
    end

    # @rbs (Grammar::Symbol next_sym, State next_state) -> void
    def set_lane_items(next_sym, next_state)
      @lane_items[next_state] = @_lane_items[next_sym]
    end

    # @rbs (Array[Item] items, State next_state) -> void
    def set_items_to_state(items, next_state)
      @items_to_state[items] = next_state
    end

    # @rbs (Grammar::Rule rule, Array[Grammar::Symbol] look_ahead) -> void
    def set_look_ahead(rule, look_ahead)
      reduce = reduces.find do |r|
        r.rule == rule
      end

      reduce.look_ahead = look_ahead
    end

    # @rbs (Grammar::Rule rule, Hash[Grammar::Symbol, Array[Action::Goto]] sources) -> void
    def set_look_ahead_sources(rule, sources)
      reduce = reduces.find do |r|
        r.rule == rule
      end

      reduce.look_ahead_sources = sources
    end

    # @rbs () -> Array[Action::Goto]
    def nterm_transitions # steep:ignore
      @nterm_transitions ||= transitions.select {|transition| transition.is_a?(Action::Goto) }
    end

    # @rbs () -> Array[Action::Shift]
    def term_transitions # steep:ignore
      @term_transitions ||= transitions.select {|transition| transition.is_a?(Action::Shift) }
    end

    # @rbs () -> Array[transition]
    def transitions
      @transitions ||= _transitions.map do |next_sym, to_items|
        if next_sym.term?
          Action::Shift.new(self, next_sym, to_items.flatten, @items_to_state[to_items])
        else
          Action::Goto.new(self, next_sym, to_items.flatten, @items_to_state[to_items])
        end
      end
    end

    # @rbs () -> Hash[Integer, transition]
    def transitions_by_symbol_number
      @transitions_by_symbol_number ||= begin
        h = {}
        transitions.each do |transition|
          h[transition.next_sym.number] = transition
        end
        h
      end
    end

    # @rbs (transition transition, State next_state) -> void
    def update_transition(transition, next_state)
      set_items_to_state(transition.to_items, next_state)
      next_state.append_predecessor(self)
      update_transitions_caches(transition)
    end

    # @rbs () -> void
    def update_transitions_caches(transition)
      new_transition =
        if transition.next_sym.term?
          Action::Shift.new(self, transition.next_sym, transition.to_items, @items_to_state[transition.to_items])
        else
          Action::Goto.new(self, transition.next_sym, transition.to_items, @items_to_state[transition.to_items])
        end

      @transitions.delete(transition)
      @transitions << new_transition
      @nterm_transitions = nil
      @term_transitions = nil
      @transitions_by_symbol_number = nil

      @follow_kernel_items[new_transition] = @follow_kernel_items.delete(transition)
      @always_follows[new_transition] = @always_follows.delete(transition)
    end

    # @rbs () -> Array[Action::Shift]
    def selected_term_transitions
      term_transitions.reject do |shift|
        shift.not_selected
      end
    end

    # Move to next state by sym
    #
    # @rbs (Grammar::Symbol sym) -> State
    def transition(sym)
      result = transitions_by_symbol_number[sym.number]&.to_state

      raise "Can not transit by #{sym} #{self}" if result.nil?

      result
    end

    # @rbs (Item item) -> Action::Reduce
    def find_reduce_by_item!(item)
      reduces.find do |r|
        r.item == item
      end || (raise "reduce is not found. #{item}")
    end

    # @rbs (Grammar::Rule default_reduction_rule) -> void
    def default_reduction_rule=(default_reduction_rule)
      @default_reduction_rule = default_reduction_rule

      reduces.each do |r|
        if r.rule == default_reduction_rule
          r.default_reduction = true
        end
      end
    end

    # @rbs () -> bool
    def has_conflicts?
      !@conflicts.empty?
    end

    # @rbs () -> Array[conflict]
    def sr_conflicts
      @conflicts.select do |conflict|
        conflict.type == :shift_reduce
      end
    end

    # @rbs () -> Array[conflict]
    def rr_conflicts
      @conflicts.select do |conflict|
        conflict.type == :reduce_reduce
      end
    end

    # Clear information related to conflicts.
    # IELR computation re-calculates conflicts and default reduction of states
    # after LALR computation.
    # Call this method before IELR computation to avoid duplicated conflicts information
    # is stored.
    #
    # @rbs () -> void
    def clear_conflicts
      @conflicts = []
      @resolved_conflicts = []
      @default_reduction_rule = nil

      term_transitions.each(&:clear_conflicts)
      reduces.each(&:clear_conflicts)
    end

    # @rbs () -> bool
    def split_state?
      @lalr_isocore != self
    end

    # Definition 3.40 (propagate_lookaheads)
    #
    # @rbs (State next_state) -> lookahead_set
    def propagate_lookaheads(next_state)
      filters = next_state.lookahead_set_filters
      next_state.kernels.map {|next_kernel|
        filter = filters[next_kernel]
        next [next_kernel, []] if filter.empty?

        lookahead_sets =
          if next_kernel.position > 1
            kernel = kernels.find {|k| k.predecessor_item_of?(next_kernel) }
            item_lookahead_set[kernel]
          else
            goto_follow_set(next_kernel.lhs)
          end

        [next_kernel, lookahead_sets & filter]
      }.to_h
    end

    # Definition 3.43 (is_compatible)
    #
    # @rbs (lookahead_set filtered_lookahead, ?dominant_contributions incoming_contributions) -> bool
    def is_compatible?(filtered_lookahead, incoming_contributions = {})
      return true if !lookaheads_recomputed || filtered_lookahead == item_lookahead_set

      # Annotations are fixed during state splitting.
      stored_contributions = (@dominant_contributions ||= {})
      @lalr_isocore.annotation_list.all? {|annotation|
        a = stored_contributions.fetch(annotation) {
          stored_contributions[annotation] = annotation.dominant_contribution(item_lookahead_set)
        }
        next true if a.nil?

        b = incoming_contributions.fetch(annotation) {
          incoming_contributions[annotation] = annotation.dominant_contribution(filtered_lookahead)
        }
        b.nil? || a == b
      }
    end

    # Definition 3.38 (lookahead_set_filters)
    #
    # @rbs () -> lookahead_set
    def lookahead_set_filters
      return @lalr_isocore.lookahead_set_filters if split_state?

      @lookahead_set_filters ||= begin
        # @type var filters: lookahead_set
        filters = kernels.map {|kernel| [kernel, []] }.to_h
        annotation_list.each do |annotation|
          # @type var contributing_kernels: Hash[Item, bool]
          contributing_kernels = {}
          annotation.contribution_matrix.each_value do |contributions|
            next if contributions.nil?
            contributions.each do |kernel, contributed|
              contributing_kernels[kernel] = true if contributed
            end
          end
          contributing_kernels.each_key do |kernel|
            filters[kernel] << annotation.token if filters.key?(kernel)
          end
        end
        filters
      end
    end

    # Definition 3.27 (inadequacy_lists)
    #
    # @rbs () -> Hash[Grammar::Symbol, Array[Action::Shift | Action::Reduce]]
    def inadequacy_list
      return @inadequacy_list if @inadequacy_list

      inadequacy_list = {}

      term_transitions.each do |shift|
        inadequacy_list[shift.next_sym] ||= []
        inadequacy_list[shift.next_sym] << shift.dup
      end
      reduces.each do |reduce|
        next if reduce.look_ahead.nil?

        reduce.look_ahead.each do |token|
          inadequacy_list[token] ||= []
          inadequacy_list[token] << reduce.dup
        end
      end

      @inadequacy_list = inadequacy_list.select {|token, actions| actions.size > 1 }
    end

    # Definition 3.30 (annotate_manifestation)
    #
    # @rbs () -> void
    def annotate_manifestation
      inadequacy_list.each {|token, actions|
        contribution_matrix = actions.map {|action|
          if action.is_a?(Action::Shift)
            [action, nil]
          else
            [action, action.rule.empty_rule? ? lhs_contributions(action.rule.lhs, token) : kernels.map {|k| [k, k.rule == action.item.rule && k.end_of_rule?] }.to_h]
          end
        }.to_h
        @annotation_list << InadequacyAnnotation.new(self, token, actions, contribution_matrix)
      }
    end

    # Definition 3.32 (annotate_predecessor)
    #
    # @rbs (State predecessor) -> void
    def annotate_predecessor(predecessor)
      propagating_list = annotation_list.map {|annotation|
        contribution_matrix = annotation.contribution_matrix.map {|action, contributions|
          if contributions.nil?
            [action, nil]
          elsif first_kernels.any? {|kernel| contributions[kernel] && predecessor.lhs_contributions(kernel.lhs, annotation.token).empty? }
            [action, nil]
          else
            cs = predecessor.lane_items[self].map {|pred_kernel, kernel|
              c = contributions[kernel] && (
                (kernel.position > 1 && predecessor.item_lookahead_set[pred_kernel].include?(annotation.token)) ||
                (kernel.position == 1 && predecessor.lhs_contributions(kernel.lhs, annotation.token)[pred_kernel])
              )
              [pred_kernel, c]
            }.to_h
            [action, cs]
          end
        }.to_h

        # Observation 3.33 (Simple Split-Stable Dominance)
        #
        # If all of contributions in the contribution_matrix are
        # always contribution or never contribution, we can stop annotate propagations
        # to the predecessor state.
        next nil if contribution_matrix.all? {|_, contributions| contributions.nil? || contributions.all? {|_, contributed| !contributed } }

        InadequacyAnnotation.new(annotation.state, annotation.token, annotation.actions, contribution_matrix)
      }.compact
      predecessor.append_annotation_list(propagating_list)
    end

    # @rbs () -> Array[Item]
    def first_kernels
      @first_kernels ||= kernels.select {|kernel| kernel.position == 1 }
    end

    # @rbs (Array[InadequacyAnnotation] propagating_list) -> void
    def append_annotation_list(propagating_list)
      propagating_by_key = propagating_list.group_by {|annotation|
        [annotation.state.id, annotation.token, annotation.actions]
      }

      annotation_list.each do |annotation|
        merging_list = propagating_by_key.delete([annotation.state.id, annotation.token, annotation.actions])
        annotation.merge_matrix(merging_list.map(&:contribution_matrix)) if merging_list
      end

      # Preserve propagation order even when unmatched keys are interleaved.
      @annotation_list += propagating_list.select {|annotation|
        propagating_by_key.key?([annotation.state.id, annotation.token, annotation.actions])
      }
    end

    # Definition 3.31 (compute_lhs_contributions)
    #
    # @rbs (Grammar::Symbol sym, Grammar::Symbol token) -> (nil | Hash[Item, bool])
    def lhs_contributions(sym, token)
      return @lhs_contributions[sym][token] unless @lhs_contributions.dig(sym, token).nil?

      transition = nterm_transitions.find {|goto| goto.next_sym == sym }
      @lhs_contributions[sym] ||= {}
      @lhs_contributions[sym][token] =
        if always_follows[transition].include?(token)
          {}
        else
          kernels.map {|kernel| [kernel, follow_kernel_items[transition][kernel] && item_lookahead_set[kernel].include?(token)] }.to_h
        end
    end

    # Definition 3.26 (item_lookahead_sets)
    #
    # @rbs () -> lookahead_set
    def item_lookahead_set
      return @item_lookahead_set if @item_lookahead_set

      @item_lookahead_set = kernels.map {|k| [k, []] }.to_h
      @item_lookahead_set = kernels.map {|kernel|
        value =
          if kernel.lhs.accept_symbol?
            []
          elsif kernel.position > 1
            prev_items = predecessors_with_item(kernel)
            prev_items.map {|st, i| st.item_lookahead_set[i] }.reduce([]) {|acc, syms| acc |= syms }
          elsif kernel.position == 1
            prev_state = @predecessors.find {|p| p.transitions.any? {|transition| transition.next_sym == kernel.lhs } }
            goto = prev_state.nterm_transitions.find {|goto| goto.next_sym == kernel.lhs }
            prev_state.goto_follows[goto]
          end
        [kernel, value]
      }.to_h
    end

    # @rbs (lookahead_set k) -> void
    def item_lookahead_set=(k)
      @item_lookahead_set = k
      @dominant_contributions = nil
    end

    # @rbs (Item item) -> Array[[State, Item]]
    def predecessors_with_item(item)
      result = []
      @predecessors.each do |pre|
        pre.items_for_rule(item.rule, item.position - 1).each do |i|
          result << [pre, i]
        end
      end
      result
    end

    # @rbs (Grammar::Rule rule, Integer position) -> Array[Item]
    def items_for_rule(rule, position)
      # Rule equality ignores IDs, so retain all matching rules at a source location.
      index = (@item_index ||= @items.group_by {|item| [item.lhs, item.rule.lineno, item.position] })
      candidates = index[[rule.lhs, rule.lineno, position]] || []
      candidates.select {|item| item.rule == rule }
    end

    # @rbs (State prev_state) -> void
    def append_predecessor(prev_state)
      seen = (@predecessor_set ||= {}.compare_by_identity)
      return if seen[prev_state]
      seen[prev_state] = true
      @predecessors << prev_state
    end

    # Definition 3.39 (compute_goto_follow_set)
    #
    # @rbs (Grammar::Symbol nterm_token) -> Array[Grammar::Symbol]
    def goto_follow_set(nterm_token)
      return [] if nterm_token.accept_symbol?
      goto = @lalr_isocore.nterm_transitions.find {|g| g.next_sym == nterm_token }

      @kernels
        .select {|kernel| @lalr_isocore.follow_kernel_items[goto][kernel] }
        .map {|kernel| item_lookahead_set[kernel] }
        .reduce(@lalr_isocore.always_follows[goto]) {|result, terms| result |= terms }
    end

    # Definition 3.8 (Goto Follows Internal Relation)
    #
    # @rbs (Action::Goto goto) -> Array[Action::Goto]
    def internal_dependencies(goto)
      return @internal_dependencies[goto] if @internal_dependencies[goto]

      dependency_symbols = (@internal_dependency_symbols ||= begin
        # @type var symbols: Hash[Grammar::Symbol, Hash[Grammar::Symbol, bool]]
        symbols = {}
        @items.each do |item|
          next unless item.position == 0
          next_sym = item.next_sym
          next unless next_sym && item.symbols_after_transition.all?(&:nullable)
          (symbols[next_sym] ||= {})[item.lhs] = true
        end
        symbols
      end)
      syms = dependency_symbols[goto.next_sym]
      @internal_dependencies[goto] = nterm_transitions.select {|goto2| syms && syms[goto2.next_sym] }
    end

    # Definition 3.5 (Goto Follows Successor Relation)
    #
    # @rbs (Action::Goto goto) -> Array[Action::Goto]
    def successor_dependencies(goto)
      return @successor_dependencies[goto] if @successor_dependencies[goto]

      @successor_dependencies[goto] = goto.to_state.nterm_transitions.select {|next_goto| next_goto.next_sym.nullable }
    end

    # Definition 3.9 (Goto Follows Predecessor Relation)
    #
    # @rbs (Action::Goto goto, ?item_origins_cache cache) -> Array[Action::Goto]
    def predecessor_dependencies(goto, cache = {})
      state_items = []
      @kernels.select {|kernel|
        kernel.position > 0 && kernel.next_sym == goto.next_sym && kernel.symbols_after_transition.all?(&:nullable)
      }.each do |item|
        state_items.concat(item_origins(item, cache))
      end

      state_items.map {|state, item|
        state.nterm_transitions.find {|goto2| goto2.next_sym == item.lhs }
      }.uniq
    end

    # @rbs (Item item, item_origins_cache cache) -> Array[item_pair]
    def item_origins(item, cache)
      stack = [[self, item]] #: Array[item_pair]
      while (key = stack.last)
        state, current = key
        if cache.key?(key)
          stack.pop
        elsif current.position == 0
          cache[key] = [key]
          stack.pop
        else
          predecessors = state.predecessors_with_item(current)
          pending = predecessors.reject {|pair| cache.key?(pair) }
          if pending.empty?
            cache[key] = predecessors.reverse.flat_map {|pair| cache.fetch(pair) }.uniq
            stack.pop
          else
            stack.concat(pending)
          end
        end
      end

      cache.fetch([self, item])
    end
  end
end
