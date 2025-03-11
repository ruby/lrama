# rbs_inline: enabled
# frozen_string_literal: true

require "set"

require_relative "counterexamples/derivation"
require_relative "counterexamples/example"
require_relative "counterexamples/path"
require_relative "counterexamples/production_path"
require_relative "counterexamples/start_path"
require_relative "counterexamples/state_item"
require_relative "counterexamples/transition_path"
require_relative "counterexamples/triple"

module Lrama
  # See: https://www.cs.cornell.edu/andru/papers/cupex/cupex.pdf
  #      4. Constructing Nonunifying Counterexamples
  class Counterexamples
    # @rbs!
    #   @states: States
    #   @transitions: Hash[[StateItem, Grammar::Symbol], StateItem]
    #   @reverse_transitions: Hash[[StateItem, Grammar::Symbol], Set[StateItem]]
    #   @productions: Hash[StateItem, Set[States::Item]]
    #   @reverse_productions: Hash[[State, Grammar::Symbol], Set[States::Item]] # Grammar::Symbol is nterm

    attr_reader :transitions #: Hash[[StateItem, Grammar::Symbol], StateItem]
    attr_reader :productions #: Hash[StateItem, Set[States::Item]]

    # @rbs (States states) -> void
    def initialize(states)
      @states = states
      setup_transitions
      setup_productions
    end

    # @rbs () -> "#<Counterexamples>"
    def to_s
      "#<Counterexamples>"
    end
    alias :inspect :to_s

    # @rbs (State conflict_state) -> Array[Example]
    def compute(conflict_state)
      conflict_state.conflicts.flat_map do |conflict|
        case conflict.type
        when :shift_reduce
          # @type var conflict: State::ShiftReduceConflict
          shift_reduce_example(conflict_state, conflict)
        when :reduce_reduce
          # @type var conflict: State::ReduceReduceConflict
          reduce_reduce_examples(conflict_state, conflict)
        end
      end.compact
    end

    private

    # @rbs () -> void
    def setup_transitions
      @transitions = {}
      @reverse_transitions = {}

      @states.states.each do |src_state|
        trans = {} #: Hash[Grammar::Symbol, State]

        src_state.transitions.each do |transition|
          trans[transition.next_sym] = transition.to_state
        end

        src_state.items.each do |src_item|
          next if src_item.end_of_rule?
          sym = src_item.next_sym
          dest_state = trans[sym]

          dest_state.kernels.each do |dest_item|
            next unless (src_item.rule == dest_item.rule) && (src_item.position + 1 == dest_item.position)
            src_state_item = StateItem.new(src_state, src_item)
            dest_state_item = StateItem.new(dest_state, dest_item)

            @transitions[[src_state_item, sym]] = dest_state_item

            # @type var key: [StateItem, Grammar::Symbol]
            key = [dest_state_item, sym]
            @reverse_transitions[key] ||= Set.new
            @reverse_transitions[key] << src_state_item
          end
        end
      end
    end

    # @rbs () -> void
    def setup_productions
      @productions = {}
      @reverse_productions = {}

      @states.states.each do |state|
        # Grammar::Symbol is LHS
        h = {} #: Hash[Grammar::Symbol, Set[States::Item]]

        state.closure.each do |item|
          sym = item.lhs

          h[sym] ||= Set.new
          h[sym] << item
        end

        state.items.each do |item|
          next if item.end_of_rule?
          next if item.next_sym.term?

          sym = item.next_sym
          state_item = StateItem.new(state, item)
          # @type var key: [State, Grammar::Symbol]
          key = [state, sym]

          @productions[state_item] = h[sym]

          @reverse_productions[key] ||= Set.new
          @reverse_productions[key] << item
        end
      end
    end

    # @rbs (State conflict_state, State::ShiftReduceConflict conflict) -> Example
    def shift_reduce_example(conflict_state, conflict)
      conflict_symbol = conflict.symbols.first
      # @type var shift_conflict_item: ::Lrama::States::Item
      shift_conflict_item = conflict_state.items.find { |item| item.next_sym == conflict_symbol }
      path2 = shortest_path(conflict_state, conflict.reduce.item, conflict_symbol)
      path1 = find_shift_conflict_shortest_path(path2, conflict_state, shift_conflict_item)

      Example.new(path1, path2, conflict, conflict_symbol, self)
    end

    # @rbs (State conflict_state, State::ReduceReduceConflict conflict) -> Example
    def reduce_reduce_examples(conflict_state, conflict)
      conflict_symbol = conflict.symbols.first
      path1 = shortest_path(conflict_state, conflict.reduce1.item, conflict_symbol)
      path2 = shortest_path(conflict_state, conflict.reduce2.item, conflict_symbol)

      Example.new(path1, path2, conflict, conflict_symbol, self)
    end

    # @rbs (::Array[Path::path]? reduce_path, State conflict_state, States::Item conflict_item) -> ::Array[Path::path]
    def find_shift_conflict_shortest_path(reduce_path, conflict_state, conflict_item)
      state_items = find_shift_conflict_shortest_state_items(reduce_path, conflict_state, conflict_item)
      build_paths_from_state_items(state_items)
    end

    # @rbs (::Array[Path::path]? reduce_path, State conflict_state, States::Item conflict_item) -> Array[StateItem]
    def find_shift_conflict_shortest_state_items(reduce_path, conflict_state, conflict_item)
      target_state_item = StateItem.new(conflict_state, conflict_item)
      result = [target_state_item]
      reversed_reduce_path = reduce_path.to_a.reverse
      # Index for state_item
      i = 0

      while (path = reversed_reduce_path[i])
        # Index for prev_state_item
        j = i + 1
        _j = j

        while (prev_path = reversed_reduce_path[j])
          if prev_path.production?
            j += 1
          else
            break
          end
        end

        state_item = path.to
        prev_state_item = prev_path&.to

        if target_state_item == state_item || target_state_item.item.start_item?
          result.concat(
            reversed_reduce_path[_j..-1] #: Array[Path::path]
              .map(&:to))
          break
        end

        if target_state_item.item.beginning_of_rule?
          queue = [] #: Array[Array[StateItem]]
          queue << [target_state_item]

          # Find reverse production
          while (sis = queue.shift)
            si = sis.last

            # Reach to start state
            if si.item.start_item?
              sis.shift
              result.concat(sis)
              target_state_item = si
              break
            end

            if si.item.beginning_of_rule?
              # @type var key: [State, Grammar::Symbol]
              key = [si.state, si.item.lhs]
              @reverse_productions[key].each do |item|
                state_item = StateItem.new(si.state, item)
                queue << (sis + [state_item])
              end
            else
              # @type var key: [StateItem, Grammar::Symbol]
              key = [si, si.item.previous_sym]
              @reverse_transitions[key].each do |prev_target_state_item|
                next if prev_target_state_item.state != prev_state_item&.state
                sis.shift
                result.concat(sis)
                result << prev_target_state_item
                target_state_item = prev_target_state_item
                i = j
                queue.clear
                break
              end
            end
          end
        else
          # Find reverse transition
          # @type var key: [StateItem, Grammar::Symbol]
          key = [target_state_item, target_state_item.item.previous_sym]
          @reverse_transitions[key].each do |prev_target_state_item|
            next if prev_target_state_item.state != prev_state_item&.state
            result << prev_target_state_item
            target_state_item = prev_target_state_item
            i = j
            break
          end
        end
      end

      result.reverse
    end

    # @rbs (Array[StateItem] state_items) -> ::Array[Path::path]
    def build_paths_from_state_items(state_items)
      state_items.zip([nil] + state_items).map do |si, prev_si|
        case
        when prev_si.nil?
          StartPath.new(si)
        when si.item.beginning_of_rule?
          ProductionPath.new(prev_si, si)
        else
          TransitionPath.new(prev_si, si)
        end
      end
    end

    # @rbs (State conflict_state, States::Item conflict_reduce_item, Grammar::Symbol conflict_term) -> ::Array[Path::path]?
    def shortest_path(conflict_state, conflict_reduce_item, conflict_term)
      queue = [] #: Array[[Triple, Array[Path::path]]]
      visited = {} #: Hash[Triple, true]
      start_state = @states.states.first #: Lrama::State
      raise "BUG: Start state should be just one kernel." if start_state.kernels.count != 1

      start = Triple.new(start_state, start_state.kernels.first, Set.new([@states.eof_symbol]))

      queue << [start, [StartPath.new(start.state_item)]]

      while true
        triple, paths = queue.shift

        next if visited[triple]
        visited[triple] = true

        # Found
        if triple.state == conflict_state && triple.item == conflict_reduce_item && triple.l.include?(conflict_term)
          return paths
        end

        # transition
        next_state_item = @transitions[[triple.state_item, triple.item.next_sym]]
        if next_state_item
          t = Triple.new(next_state_item.state, next_state_item.item, triple.l)
          queue << [t, paths + [TransitionPath.new(triple.state_item, t.state_item)]]
        end

        # production step
        @productions[triple.state_item]&.each do |item|
          next unless triple.item.next_sym && triple.item.next_sym == item.lhs
          l = follow_l(triple.item, triple.l)
          t = Triple.new(triple.state, item, l)
          queue << [t, paths + [ProductionPath.new(triple.state_item, t.state_item)]]
        end

        break if queue.empty?
      end

      return nil
    end

    # @rbs (States::Item item, Set[Grammar::Symbol] current_l) -> Set[Grammar::Symbol]
    def follow_l(item, current_l)
      # 1. follow_L (A -> X1 ... Xn-1 • Xn) = L
      # 2. follow_L (A -> X1 ... Xk • Xk+1 Xk+2 ... Xn) = {Xk+2} if Xk+2 is a terminal
      # 3. follow_L (A -> X1 ... Xk • Xk+1 Xk+2 ... Xn) = FIRST(Xk+2) if Xk+2 is a nonnullable nonterminal
      # 4. follow_L (A -> X1 ... Xk • Xk+1 Xk+2 ... Xn) = FIRST(Xk+2) + follow_L (A -> X1 ... Xk+1 • Xk+2 ... Xn) if Xk+2 is a nullable nonterminal
      case
      when item.number_of_rest_symbols == 1
        current_l
      when item.next_next_sym.term?
        Set.new([item.next_next_sym])
      when !item.next_next_sym.nullable
        item.next_next_sym.first_set
      else
        item.next_next_sym.first_set + follow_l(item.new_by_next_position, current_l)
      end
    end
  end
end
