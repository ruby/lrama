require "lrama/state/reduce"
require "lrama/state/reduce_reduce_conflict"
require "lrama/state/resolved_conflict"
require "lrama/state/shift"
require "lrama/state/shift_reduce_conflict"
require "lrama/state/inadequacy_annotation"

module Lrama
  class State
    attr_reader :id, :accessing_symbol, :kernels, :conflicts, :resolved_conflicts,
                :default_reduction_rule, :closure, :items, :predecessors
    attr_accessor :shifts, :reduces, :lalr_isocore

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
    end

    def closure=(closure)
      @closure = closure
      @items = @kernels + @closure
    end

    def non_default_reduces
      reduces.reject do |reduce|
        reduce.rule == @default_reduction_rule
      end
    end

    def compute_shifts_reduces
      _shifts = {}
      reduces = []
      items.each do |item|
        # TODO: Consider what should be pushed
        if item.end_of_rule?
          reduces << Reduce.new(item)
        else
          key = item.next_sym
          _shifts[key] ||= []
          _shifts[key] << item.new_by_next_position
        end
      end

      # It seems Bison 3.8.2 iterates transitions order by symbol number
      shifts = _shifts.sort_by do |next_sym, new_items|
        next_sym.number
      end.map do |next_sym, new_items|
        Shift.new(next_sym, new_items.flatten)
      end
      self.shifts = shifts.freeze
      self.reduces = reduces.freeze
    end

    def set_items_to_state(items, next_state)
      @items_to_state[items] = next_state
    end

    def set_look_ahead(rule, look_ahead)
      reduce = reduces.find do |r|
        r.rule == rule
      end

      reduce.look_ahead = look_ahead
    end

    def nterm_transitions
      @nterm_transitions ||= transitions.select {|shift, _| shift.next_sym.nterm? }
    end

    def term_transitions
      @term_transitions ||= transitions.select {|shift, _| shift.next_sym.term? }
    end

    def transitions
      @transitions ||= shifts.map {|shift| [shift, @items_to_state[shift.next_items]] }
    end

    def update_transition(shift, next_state)
      set_items_to_state(shift.next_items, next_state)
      @transitions = shifts.map {|sh| [sh, @items_to_state[sh.next_items]] }
    end

    def selected_term_transitions
      term_transitions.reject do |shift, next_state|
        shift.not_selected
      end
    end

    # Move to next state by sym
    def transition(sym)
      result = nil

      if sym.term?
        term_transitions.each do |shift, next_state|
          term = shift.next_sym
          result = next_state if term == sym
        end
      else
        nterm_transitions.each do |shift, next_state|
          nterm = shift.next_sym
          result = next_state if nterm == sym
        end
      end

      raise "Can not transit by #{sym} #{self}" if result.nil?

      result
    end

    def find_reduce_by_item!(item)
      reduces.find do |r|
        r.item == item
      end || (raise "reduce is not found. #{item}")
    end

    def default_reduction_rule=(default_reduction_rule)
      @default_reduction_rule = default_reduction_rule

      reduces.each do |r|
        if r.rule == default_reduction_rule
          r.default_reduction = true
        end
      end
    end

    def has_conflicts?
      !@conflicts.empty?
    end

    def sr_conflicts
      @conflicts.select do |conflict|
        conflict.type == :shift_reduce
      end
    end

    def rr_conflicts
      @conflicts.select do |conflict|
        conflict.type == :reduce_reduce
      end
    end

    def always_follows(shift, next_state)
      internal_dependencies(shift, next_state).union(successor_dependencies(shift, next_state)).reduce([]) {|result, transition| result += transition[1].term_transitions.map {|shift, _| shift.next_sym } }
    end

    def internal_dependencies(shift, next_state)
      nterm_transitions.select {|other_shift, _|
        @items.find {|item| item.next_sym == shift.next_sym && item.lhs == other_shift.next_sym && item.symbols_after_dot.all?(&:nullable) }
      }.reduce([[shift, next_state]]) {|result, transition|
        result += internal_dependencies(*transition)
      }
    end

    def successor_dependencies(shift, next_state)
      next_state.nterm_transitions.select {|other_shift, _|
        other_shift.next_sym.nullable
      }.reduce([[shift, next_state]]) {|result, transition|
        result += successor_dependencies(*transition)
      }
    end

    def inspect
      "#{id} -> #{@kernels.map(&:to_s).join(', ')}"
    end

    def inadequacy_list
      return @inadequacy_list if @inadequacy_list

      shift_contributions = shifts.to_h {|shift|
        [shift.next_sym, [shift]]
      }
      reduce_contributions = reduces.map {|reduce|
        (reduce.look_ahead || []).to_h {|sym|
          [sym, [reduce]]
        }
      }.reduce(Hash.new([])) {|hash, cont|
        hash.merge(cont) {|_, a, b| a.union(b) }
      }

      list = shift_contributions.merge(reduce_contributions) {|_, a, b| a.union(b) }
      @inadequacy_list = list.select {|token, actions| token.term? && actions.size > 1 }
    end

    def annotate_manifestation
      inadequacy_list.map {|token, actions|
        actions.map {|action|
          if action.is_a?(Shift)
            [InadequacyAnnotation.new(token: token, action: action, item: nil, contributed: false)]
          elsif action.is_a?(Reduce)
            if action.rule.empty_rule?
              lhs_contributions(action.rule.lhs, token).map {|kernel, contributed|
                InadequacyAnnotation.new(token: token, action: action, item: kernel, contributed: contributed)
              }
            else
              kernels.map {|kernel|
                contributed = kernel.rule == action.rule && kernel.end_of_rule?
                InadequacyAnnotation.new(token: token, action: action, item: kernel, contributed: contributed)
              }
            end
          end
        }
      }
    end

    def annotate_predecessor(annotation_list)
      annotation_list.reduce([]) {|annotation|
        next [token, {}] if annotation.no_contributions? || actions.any? {|action, hash|
          p action, hash
          hash.keys.any? {|item| hash[item] && item.position == 1 && compute_lhs_contributions(state, item.lhs, token).empty? }
        }
        [
          token, actions.to_h {|action, hash|
            [
              action, hash.to_h {|item, _|
                kernel = state.kernels.find {|k| k.rule == item.rule && k.position == item.position - 1 }
                [kernel,
                 hash[item] &&
                 (
                   !kernel.nil? && (state.item_lookahead_set[kernel].include?(token)) ||
                   (item.position == 1 && compute_lhs_contributions(state, item.lhs, token)[item])
                 )
                ]
              }
            ]
          }
        ]
      }
    end

    def item_lookahead_set
      @item_lookahead_set ||=
        kernels.to_h {|item|
          value =
            if item.position > 1
              prev_state, prev_item = predecessor_with_item(item)
              prev_state.item_lookahead_set[prev_item]
            elsif item.position == 1
              prev_state = predecessors.find {|p| p.shifts.any? {|shift| shift.next_sym == item.lhs } }
              shift, next_state = prev_state.nterm_transitions.find {|shift, _| shift.next_sym == item.lhs }
              prev_state.goto_follows(shift, next_state)
            else
              []
            end
          [item, value]
        }
    end

    def item_lookahead_set=(k)
      @item_lookahead_set = k
    end

    def predecessor_with_item(item)
      predecessors.each do |state|
        state.kernels.each do |kernel|
          return [state, kernel] if kernel.rule == item.rule && kernel.position == item.position - 1
        end
      end
    end

    def lhs_contributions(sym, token)
      shift, next_state = nterm_transitions.find {|sh, _| sh.next_sym == sym }
      if always_follows(shift, next_state).include?(token)
        []
      else
        kernels.map {|kernel| [kernel, follow_kernel?(kernel) && item_lookahead_set[kernel].include?(token)] }
      end
    end

    def follow_kernel?(item)
      item.symbols_after_dot.all?(&:nullable)
    end

    def follow_kernel_items(shift, next_state, item)
      internal_dependencies(shift, next_state).any? {|shift, _| shift.next_sym == item.next_sym } && item.symbols_after_dot.all?(&:nullable)
    end

    def next_terms
      shifts.filter_map {|shift| shift.next_sym.term? && shift.next_sym }
    end

    def append_predecessor(prev_state)
      @predecessors << prev_state
      @predecessors.uniq!
    end

    def goto_follows(shift, next_state)
      include_dependencies(shift, next_state).reduce([]) {|result, goto|
        st, sh, next_st = goto
        result.union(st.always_follows(sh, next_st))
      }
    end

    def include_dependencies(shift, next_state)
      internal = internal_dependencies(shift, next_state).map {|sh, next_st| [self, sh, next_st] }
      pred = predecessor_dependencies(shift, next_state)

      return internal if pred.empty?
      dependency = internal.union(pred)

      dependency.reduce(dependency) {|result, goto| result.union(compute_include_dependencies(*goto)) }
    end

    def predecessor_dependencies(shift, next_state)
      item = kernels.find {|kernel| kernel.next_sym == shift.next_sym }
      return [] unless item.symbols_after_transition.all?(&:nullable)

      st = @predecessors.find {|p| p.items.find {|i| i.rule == item.rule && i.position == item.position - 1 } }
      sh, next_st = s.nterm_transitions.find {|shift, _| shift.next_token == item.lhs }
      [[s, sh, next_st]]
    end
  end
end
