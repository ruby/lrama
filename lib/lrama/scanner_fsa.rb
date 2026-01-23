# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  # Scanner Finite State Automaton for PSLR(1)
  # Built from token patterns defined by %token-pattern directives
  # Based on Definitions 3.2.12, 3.2.13 from the PSLR dissertation
  class ScannerFSA
    # Represents a state in the scanner FSA
    class State
      attr_reader :id #: Integer
      attr_reader :transitions #: Hash[String, Integer]
      attr_reader :accepting_tokens #: Array[Grammar::TokenPattern]

      # @rbs (Integer id) -> void
      def initialize(id)
        @id = id
        @transitions = {}
        @accepting_tokens = []
      end

      # @rbs () -> bool
      def accepting?
        !@accepting_tokens.empty?
      end

      # @rbs (String char, Integer target_state_id) -> void
      def add_transition(char, target_state_id)
        @transitions[char] = target_state_id
      end

      # @rbs (Grammar::TokenPattern token_pattern) -> void
      def add_accepting_token(token_pattern)
        @accepting_tokens << token_pattern
      end
    end

    attr_reader :states #: Array[State]
    attr_reader :initial_state #: State
    attr_reader :token_patterns #: Array[Grammar::TokenPattern]

    # @rbs (Array[Grammar::TokenPattern] token_patterns) -> void
    def initialize(token_patterns)
      @token_patterns = token_patterns
      @states = []
      @state_counter = 0
      build_fsa
    end

    # Returns the accepting state for a given FSA state
    # Definition 3.2.13 (state_to_accepting_state)
    # @rbs (Integer state_id) -> State?
    def state_to_accepting_state(state_id)
      state = @states[state_id]
      return nil unless state&.accepting?
      state
    end

    # Returns the set of tokens accepted at FSA state ss
    # Definition 3.2.12 acc(ss)
    # @rbs (Integer state_id) -> Array[Grammar::TokenPattern]
    def acc_ss(state_id)
      state = @states[state_id]
      return [] unless state
      state.accepting_tokens
    end

    # Simulate the FSA on input string starting from initial state
    # Returns all accepting states reached during the scan
    # @rbs (String input) -> Array[{state: State, position: Integer, token: Grammar::TokenPattern}]
    def scan(input)
      results = []
      current_state_id = 0

      input.each_char.with_index do |char, index|
        current_state = @states[current_state_id]
        break unless current_state

        next_state_id = current_state.transitions[char]
        break unless next_state_id

        current_state_id = next_state_id
        next_state = @states[next_state_id]

        if next_state.accepting?
          next_state.accepting_tokens.each do |token_pattern|
            results << { state: next_state, position: index + 1, token: token_pattern }
          end
        end
      end

      results
    end

    private

    # Build the FSA from token patterns
    # Uses Thompson's construction for NFAs followed by subset construction for DFA
    # @rbs () -> void
    def build_fsa
      return if @token_patterns.empty?

      # Create initial state
      @initial_state = create_state

      # Build NFA for each token pattern and convert to DFA
      nfa_states = build_nfa
      convert_nfa_to_dfa(nfa_states)
    end

    # @rbs () -> State
    def create_state
      state = State.new(@state_counter)
      @state_counter += 1
      @states << state
      state
    end

    # Simple NFA state for regex compilation
    class NFAState
      attr_reader :id #: Integer
      attr_accessor :transitions #: Hash[String?, Array[NFAState]]
      attr_accessor :accepting_token #: Grammar::TokenPattern?

      # @rbs (Integer id) -> void
      def initialize(id)
        @id = id
        @transitions = Hash.new { |h, k| h[k] = [] }
        @accepting_token = nil
      end

      # @rbs (String? char, NFAState target) -> void
      def add_transition(char, target)
        @transitions[char] << target
      end

      # @rbs () -> bool
      def accepting?
        !@accepting_token.nil?
      end
    end

    # Build NFA from all token patterns
    # @rbs () -> Array[NFAState]
    def build_nfa
      nfa_states = []
      nfa_counter = [0]

      # Create NFA start state
      nfa_start = create_nfa_state(nfa_counter, nfa_states)

      @token_patterns.each do |token_pattern|
        # Build NFA fragment for this pattern
        start_state, end_state = compile_regex(token_pattern.regex_pattern, nfa_counter, nfa_states)

        # Connect NFA start to this pattern's start with epsilon
        nfa_start.add_transition(nil, start_state)

        # Mark end state as accepting
        end_state.accepting_token = token_pattern
      end

      nfa_states
    end

    # @rbs (Array[Integer] counter, Array[NFAState] states) -> NFAState
    def create_nfa_state(counter, states)
      state = NFAState.new(counter[0])
      counter[0] += 1
      states << state
      state
    end

    # Compile a regex pattern to NFA fragment
    # Returns [start_state, end_state]
    # @rbs (String pattern, Array[Integer] counter, Array[NFAState] states) -> [NFAState, NFAState]
    def compile_regex(pattern, counter, states)
      # Simple regex compiler supporting:
      # - Literal characters
      # - Character classes [...]
      # - Quantifiers *, +, ?
      # - Alternation |
      # - Grouping ()

      compile_sequence(pattern, 0, counter, states)
    end

    # Compile a sequence of regex elements
    # @rbs (String pattern, Integer pos, Array[Integer] counter, Array[NFAState] states) -> [NFAState, NFAState]
    def compile_sequence(pattern, pos, counter, states)
      fragments = []
      i = pos

      while i < pattern.length
        char = pattern[i]

        case char
        when '\\'
          # Escape sequence
          if i + 1 < pattern.length
            i += 1
            next_char = pattern[i]
            case next_char
            when 'd'
              # \d matches digit
              frag = compile_char_class('0-9', counter, states)
            when 'w'
              # \w matches word character
              frag = compile_char_class('a-zA-Z0-9_', counter, states)
            when 's'
              # \s matches whitespace
              frag = compile_char_class(' \t\n\r\f\v', counter, states)
            else
              # Literal escaped character
              frag = compile_literal(next_char, counter, states)
            end
            fragments << frag
          end
        when '['
          # Character class
          class_end = pattern.index(']', i)
          raise "Unclosed character class in pattern: #{pattern}" unless class_end

          char_class = pattern[i + 1...class_end]
          frag = compile_char_class(char_class, counter, states)
          fragments << frag
          i = class_end
        when '*', '+', '?'
          # Quantifier - modify the last fragment
          if fragments.empty?
            raise "Quantifier #{char} without preceding element in pattern: #{pattern}"
          end
          last_frag = fragments.pop
          quantified = apply_quantifier(last_frag, char, counter, states)
          fragments << quantified
        when '|'
          # Alternation - compile remaining and merge
          left_start, left_end = concatenate_fragments(fragments, counter, states)
          right_start, right_end = compile_sequence(pattern, i + 1, counter, states)

          # Create alternation
          alt_start = create_nfa_state(counter, states)
          alt_end = create_nfa_state(counter, states)

          alt_start.add_transition(nil, left_start)
          alt_start.add_transition(nil, right_start)
          left_end.add_transition(nil, alt_end)
          right_end.add_transition(nil, alt_end)

          return [alt_start, alt_end]
        when '('
          # Find matching closing paren
          depth = 1
          j = i + 1
          while j < pattern.length && depth > 0
            if pattern[j] == '('
              depth += 1
            elsif pattern[j] == ')'
              depth -= 1
            end
            j += 1
          end
          raise "Unclosed group in pattern: #{pattern}" if depth > 0

          group_content = pattern[i + 1...j - 1]
          frag = compile_sequence(group_content, 0, counter, states)
          fragments << frag
          i = j - 1
        when ')'
          # End of group - return
          break
        when '.'
          # Match any character (simplified: printable ASCII)
          frag = compile_any_char(counter, states)
          fragments << frag
        else
          # Literal character
          frag = compile_literal(char, counter, states)
          fragments << frag
        end

        i += 1
      end

      if fragments.empty?
        # Empty pattern
        state = create_nfa_state(counter, states)
        return [state, state]
      end

      concatenate_fragments(fragments, counter, states)
    end

    # Compile a single literal character
    # @rbs (String char, Array[Integer] counter, Array[NFAState] states) -> [NFAState, NFAState]
    def compile_literal(char, counter, states)
      start_state = create_nfa_state(counter, states)
      end_state = create_nfa_state(counter, states)
      start_state.add_transition(char, end_state)
      [start_state, end_state]
    end

    # Compile a character class [...]
    # @rbs (String char_class, Array[Integer] counter, Array[NFAState] states) -> [NFAState, NFAState]
    def compile_char_class(char_class, counter, states)
      start_state = create_nfa_state(counter, states)
      end_state = create_nfa_state(counter, states)

      chars = expand_char_class(char_class)
      chars.each do |c|
        start_state.add_transition(c, end_state)
      end

      [start_state, end_state]
    end

    # Expand character class string to array of characters
    # @rbs (String char_class) -> Array[String]
    def expand_char_class(char_class)
      chars = []
      i = 0
      negated = false

      if char_class[0] == '^'
        negated = true
        i = 1
      end

      while i < char_class.length
        if i + 2 < char_class.length && char_class[i + 1] == '-'
          # Range
          start_char = char_class[i]
          end_char = char_class[i + 2]
          (start_char..end_char).each { |c| chars << c }
          i += 3
        else
          chars << char_class[i]
          i += 1
        end
      end

      if negated
        all_printable = (32..126).map(&:chr)
        chars = all_printable - chars
      end

      chars
    end

    # Compile . (any character)
    # @rbs (Array[Integer] counter, Array[NFAState] states) -> [NFAState, NFAState]
    def compile_any_char(counter, states)
      start_state = create_nfa_state(counter, states)
      end_state = create_nfa_state(counter, states)

      # Match printable ASCII
      (32..126).each do |code|
        start_state.add_transition(code.chr, end_state)
      end

      [start_state, end_state]
    end

    # Apply a quantifier to a fragment
    # @rbs ([NFAState, NFAState] fragment, String quantifier, Array[Integer] counter, Array[NFAState] states) -> [NFAState, NFAState]
    def apply_quantifier(fragment, quantifier, counter, states)
      frag_start, frag_end = fragment

      case quantifier
      when '*'
        # Zero or more
        new_start = create_nfa_state(counter, states)
        new_end = create_nfa_state(counter, states)

        new_start.add_transition(nil, frag_start)
        new_start.add_transition(nil, new_end)
        frag_end.add_transition(nil, frag_start)
        frag_end.add_transition(nil, new_end)

        [new_start, new_end]
      when '+'
        # One or more
        new_end = create_nfa_state(counter, states)

        frag_end.add_transition(nil, frag_start)
        frag_end.add_transition(nil, new_end)

        [frag_start, new_end]
      when '?'
        # Zero or one
        new_start = create_nfa_state(counter, states)
        new_end = create_nfa_state(counter, states)

        new_start.add_transition(nil, frag_start)
        new_start.add_transition(nil, new_end)
        frag_end.add_transition(nil, new_end)

        [new_start, new_end]
      else
        fragment
      end
    end

    # Concatenate multiple NFA fragments into one
    # @rbs (Array[[NFAState, NFAState]] fragments, Array[Integer] counter, Array[NFAState] states) -> [NFAState, NFAState]
    def concatenate_fragments(fragments, counter, states)
      return create_nfa_state(counter, states).then { |s| [s, s] } if fragments.empty?
      return fragments[0] if fragments.size == 1

      result_start = fragments[0][0]
      current_end = fragments[0][1]

      fragments[1..-1].each do |frag_start, frag_end|
        current_end.add_transition(nil, frag_start)
        current_end = frag_end
      end

      [result_start, current_end]
    end

    # Convert NFA to DFA using subset construction
    # @rbs (Array[NFAState] nfa_states) -> void
    def convert_nfa_to_dfa(nfa_states)
      return if nfa_states.empty?

      # Clear existing DFA states
      @states = []
      @state_counter = 0

      # Compute epsilon closure of start state
      nfa_start = nfa_states[0]
      start_closure = epsilon_closure([nfa_start])

      # Map NFA state sets to DFA states
      dfa_states = {}
      work_list = [start_closure]
      dfa_states[start_closure.map(&:id).sort] = create_state

      @initial_state = @states[0]

      # Mark accepting tokens for initial state
      start_closure.each do |nfa_state|
        if nfa_state.accepting?
          @initial_state.add_accepting_token(nfa_state.accepting_token)
        end
      end

      while !work_list.empty?
        current_nfa_set = work_list.shift
        current_dfa = dfa_states[current_nfa_set.map(&:id).sort]

        # Find all possible transitions
        transitions = {}
        current_nfa_set.each do |nfa_state|
          nfa_state.transitions.each do |char, targets|
            next if char.nil? # Skip epsilon transitions
            transitions[char] ||= []
            transitions[char].concat(targets)
          end
        end

        transitions.each do |char, targets|
          target_closure = epsilon_closure(targets.uniq)
          target_key = target_closure.map(&:id).sort

          unless dfa_states.key?(target_key)
            new_dfa_state = create_state
            dfa_states[target_key] = new_dfa_state

            # Mark accepting tokens
            target_closure.each do |nfa_state|
              if nfa_state.accepting?
                new_dfa_state.add_accepting_token(nfa_state.accepting_token)
              end
            end

            work_list << target_closure
          end

          current_dfa.add_transition(char, dfa_states[target_key].id)
        end
      end
    end

    # Compute epsilon closure of a set of NFA states
    # @rbs (Array[NFAState] nfa_states) -> Array[NFAState]
    def epsilon_closure(nfa_states)
      closure = nfa_states.dup
      work_list = nfa_states.dup

      while !work_list.empty?
        state = work_list.shift
        epsilon_targets = state.transitions[nil] || []

        epsilon_targets.each do |target|
          unless closure.include?(target)
            closure << target
            work_list << target
          end
        end
      end

      closure
    end
  end
end
