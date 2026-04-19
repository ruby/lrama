# rbs_inline: enabled
# frozen_string_literal: true

require "set"

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

    # Returns token pairs that can be in an identity or length scanner conflict.
    # Pair keys are sorted token names.
    # @rbs () -> Set[[String, String]]
    def pairwise_conflict_pairs
      pairs = Set.new

      @states.each do |state|
        accepting_names = state.accepting_tokens.map(&:name).uniq
        accepting_names.combination(2) do |left, right|
          pairs << pair_key(left, right)
        end
      end

      @states.each do |start|
        shorter_names = start.accepting_tokens.map(&:name).uniq
        next if shorter_names.empty?

        visited = Set.new
        stack = start.transitions.values.uniq

        until stack.empty?
          state_id = stack.pop
          next if visited.include?(state_id)

          visited << state_id
          state = @states[state_id]
          next unless state

          longer_names = state.accepting_tokens.map(&:name).uniq
          shorter_names.product(longer_names).each do |left, right|
            pairs << pair_key(left, right) if left != right
          end
          state.transitions.each_value {|next_id| stack << next_id }
        end
      end

      pairs
    end

    # @rbs (String left, String right) -> bool
    def pairwise_conflict?(left, right)
      pairwise_conflict_pairs.include?(pair_key(left, right))
    end

    private

    # @rbs (String left, String right) -> [String, String]
    def pair_key(left, right)
      left <= right ? [left, right] : [right, left]
    end

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
    class PatternError < StandardError; end

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

    class Fragment
      attr_reader :start_state #: NFAState
      attr_reader :end_state #: NFAState
      attr_reader :nullable #: bool

      # @rbs (NFAState start_state, NFAState end_state, bool nullable) -> void
      def initialize(start_state, end_state, nullable)
        @start_state = start_state
        @end_state = end_state
        @nullable = nullable
      end

      # @rbs () -> [NFAState, NFAState]
      def to_ary
        [@start_state, @end_state]
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
        begin
          start_state, end_state = compile_regex(token_pattern.regex_pattern, nfa_counter, nfa_states)
        rescue PatternError => e
          raise PatternError,
            "%token-pattern #{token_pattern.name} at line #{token_pattern.lineno} " \
            "has unsupported pattern /#{token_pattern.regex_pattern}/: #{e.message}"
        end

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

    ASCII_CHARS = (0..127).map(&:chr).freeze #: Array[String]
    ANY_CHARS = (ASCII_CHARS - ["\n"]).freeze #: Array[String]
    DIGIT_CHARS = ("0".."9").to_a.freeze #: Array[String]
    WORD_CHARS = (("a".."z").to_a + ("A".."Z").to_a + DIGIT_CHARS + ["_"]).freeze #: Array[String]
    WHITESPACE_CHARS = [" ", "\t", "\n", "\r", "\f", "\v"].freeze #: Array[String]
    QUANTIFIERS = ["*", "+", "?"].freeze #: Array[String]
    ESCAPED_LITERAL_CHARS = ["/", "\\", "*", "+", "?", "(", ")", "[", "]", "{", "}", ".", "|", "^", "$", "-"].freeze #: Array[String]

    # Compile a regex pattern to NFA fragment. The supported dialect is a small
    # ASCII regular-expression subset for PSLR pseudo scanning.
    # @rbs (String pattern, Array[Integer] counter, Array[NFAState] states) -> [NFAState, NFAState]
    def compile_regex(pattern, counter, states)
      raise PatternError, "empty patterns are not allowed" if pattern.empty?

      fragment, pos = compile_expression(pattern, 0, counter, states)
      raise PatternError, "unexpected trailing input at offset #{pos}" if pos < pattern.length
      raise PatternError, "nullable patterns are not allowed" if fragment.nullable

      [fragment.start_state, fragment.end_state]
    end

    # @rbs (String pattern, Integer pos, Array[Integer] counter, Array[NFAState] states, ?String? stop_char) -> [Fragment, Integer]
    def compile_expression(pattern, pos, counter, states, stop_char = nil)
      fragment, pos = compile_sequence(pattern, pos, counter, states, stop_char)
      raise PatternError, empty_sequence_message(stop_char) unless fragment

      alternatives = [fragment]

      while pos < pattern.length && pattern[pos] == "|"
        pos += 1
        fragment, pos = compile_sequence(pattern, pos, counter, states, stop_char)
        raise PatternError, "empty alternatives are not allowed" unless fragment

        alternatives << fragment
      end

      if stop_char
        raise PatternError, "unclosed group" unless pos < pattern.length && pattern[pos] == stop_char

        pos += 1
      elsif pos < pattern.length && pattern[pos] == ")"
        raise PatternError, "unmatched close group at offset #{pos}"
      end

      [alternate_fragments(alternatives, counter, states), pos]
    end

    # @rbs (String pattern, Integer pos, Array[Integer] counter, Array[NFAState] states, String? stop_char) -> [Fragment?, Integer]
    def compile_sequence(pattern, pos, counter, states, stop_char)
      fragments = []
      i = pos

      while i < pattern.length
        char = pattern[i]
        break if char == "|" || (stop_char && char == stop_char)

        case char
        when '\\'
          frag, i = compile_escape(pattern, i, counter, states)
          fragments << frag
          next
        when '['
          class_end = find_character_class_end(pattern, i)
          raise PatternError, "unclosed character class at offset #{i}" unless class_end

          char_class = pattern[i + 1...class_end]
          frag = compile_char_class(char_class, counter, states)
          fragments << frag
          i = class_end
        when '*', '+', '?'
          # Quantifier - modify the last fragment
          if fragments.empty?
            raise PatternError, "quantifier #{char} without preceding element at offset #{i}"
          end
          fragments << apply_quantifier(fragments.pop, char, counter, states)
        when '|'
          break
        when '('
          frag, i = compile_expression(pattern, i + 1, counter, states, ")")
          fragments << frag
          next
        when ')'
          raise PatternError, "unmatched close group at offset #{i}"
        when '.'
          frag = compile_any_char(counter, states)
          fragments << frag
        when ']'
          raise PatternError, "unmatched character class close at offset #{i}"
        else
          frag = compile_literal(char, counter, states)
          fragments << frag
        end

        i += 1
      end

      return [nil, i] if fragments.empty?

      [concatenate_fragments(fragments, counter, states), i]
    end

    # @rbs (String? stop_char) -> String
    def empty_sequence_message(stop_char)
      stop_char ? "empty groups are not allowed" : "empty patterns are not allowed"
    end

    # @rbs (String pattern, Integer offset, Array[Integer] counter, Array[NFAState] states) -> [Fragment, Integer]
    def compile_escape(pattern, offset, counter, states)
      raise PatternError, "dangling escape at offset #{offset}" if offset + 1 >= pattern.length

      escaped = pattern[offset + 1]
      fragment =
        case escaped
        when "d"
          compile_chars(DIGIT_CHARS, counter, states)
        when "w"
          compile_chars(WORD_CHARS, counter, states)
        when "s"
          compile_chars(WHITESPACE_CHARS, counter, states)
        when "n"
          compile_literal("\n", counter, states)
        when "t"
          compile_literal("\t", counter, states)
        when "r"
          compile_literal("\r", counter, states)
        when "f"
          compile_literal("\f", counter, states)
        when "v"
          compile_literal("\v", counter, states)
        else
          raise PatternError, "unsupported escape \\#{escaped} at offset #{offset}" if escaped.match?(/[[:alnum:]]/)

          unless ESCAPED_LITERAL_CHARS.include?(escaped)
            raise PatternError, "unsupported escape \\#{escaped} at offset #{offset}"
          end
          compile_literal(escaped, counter, states)
        end

      [fragment, offset + 2]
    end

    # Compile a single literal character
    # @rbs (String char, Array[Integer] counter, Array[NFAState] states) -> Fragment
    def compile_literal(char, counter, states)
      compile_chars([char], counter, states)
    end

    # @rbs (Array[String] chars, Array[Integer] counter, Array[NFAState] states) -> Fragment
    def compile_chars(chars, counter, states)
      raise PatternError, "empty character classes are not allowed" if chars.empty?

      start_state = create_nfa_state(counter, states)
      end_state = create_nfa_state(counter, states)
      chars.uniq.each do |char|
        start_state.add_transition(char, end_state)
      end
      Fragment.new(start_state, end_state, false)
    end

    # Compile a character class [...]
    # @rbs (String char_class, Array[Integer] counter, Array[NFAState] states) -> Fragment
    def compile_char_class(char_class, counter, states)
      compile_chars(expand_char_class(char_class), counter, states)
    end

    # Expand character class string to array of characters
    # @rbs (String char_class) -> Array[String]
    def expand_char_class(char_class)
      raise PatternError, "empty character classes are not allowed" if char_class.empty?

      chars = []
      i = 0
      negated = false

      if char_class[0] == '^'
        negated = true
        i = 1
        raise PatternError, "negated character classes must include at least one character" if i >= char_class.length
      end

      while i < char_class.length
        element_chars, i = read_char_class_element(char_class, i)

        if i < char_class.length && char_class[i] == "-" && i + 1 < char_class.length
          i += 1
          range_end_chars, i = read_char_class_element(char_class, i)
          chars.concat(expand_char_range(element_chars, range_end_chars))
        else
          chars.concat(element_chars)
        end
      end

      if negated
        chars = ASCII_CHARS - chars
      end

      chars.uniq
    end

    # @rbs (String pattern, Integer offset) -> Integer?
    def find_character_class_end(pattern, offset)
      i = offset + 1
      while i < pattern.length
        if pattern[i] == "\\"
          raise PatternError, "dangling escape in character class at offset #{i}" if i + 1 >= pattern.length

          i += 2
          next
        end

        return i if pattern[i] == "]"

        i += 1
      end

      nil
    end

    # @rbs (String char_class, Integer offset) -> [Array[String], Integer]
    def read_char_class_element(char_class, offset)
      raise PatternError, "dangling range operator in character class" if offset >= char_class.length

      char = char_class[offset]
      if char == "\\"
        raise PatternError, "dangling escape in character class" if offset + 1 >= char_class.length

        escaped = char_class[offset + 1]
        return [escaped_char_class_chars(escaped, offset), offset + 2]
      end

      [[char], offset + 1]
    end

    # @rbs (String char, Integer offset) -> Array[String]
    def escaped_char_class_chars(char, offset)
      case char
      when "d"
        DIGIT_CHARS
      when "w"
        WORD_CHARS
      when "s"
        WHITESPACE_CHARS
      when "t"
        ["\t"]
      when "n"
        ["\n"]
      when "r"
        ["\r"]
      when "f"
        ["\f"]
      when "v"
        ["\v"]
      else
        raise PatternError, "unsupported escape \\#{char} in character class at offset #{offset}" if char.match?(/[[:alnum:]]/)

        [char]
      end
    end

    # @rbs (Array[String] start_chars, Array[String] end_chars) -> Array[String]
    def expand_char_range(start_chars, end_chars)
      if start_chars.size != 1 || end_chars.size != 1
        raise PatternError, "character class ranges must use single-character endpoints"
      end

      start_char = start_chars.first
      end_char = end_chars.first
      if start_char.ord > end_char.ord
        raise PatternError, "invalid character class range #{start_char}-#{end_char}"
      end

      (start_char.ord..end_char.ord).map(&:chr)
    end

    # Compile . (any character)
    # @rbs (Array[Integer] counter, Array[NFAState] states) -> Fragment
    def compile_any_char(counter, states)
      compile_chars(ANY_CHARS, counter, states)
    end

    # Apply a quantifier to a fragment
    # @rbs (Fragment fragment, String quantifier, Array[Integer] counter, Array[NFAState] states) -> Fragment
    def apply_quantifier(fragment, quantifier, counter, states)
      frag_start = fragment.start_state
      frag_end = fragment.end_state

      case quantifier
      when '*'
        # Zero or more
        new_start = create_nfa_state(counter, states)
        new_end = create_nfa_state(counter, states)

        new_start.add_transition(nil, frag_start)
        new_start.add_transition(nil, new_end)
        frag_end.add_transition(nil, frag_start)
        frag_end.add_transition(nil, new_end)

        Fragment.new(new_start, new_end, true)
      when '+'
        # One or more
        new_end = create_nfa_state(counter, states)

        frag_end.add_transition(nil, frag_start)
        frag_end.add_transition(nil, new_end)

        Fragment.new(frag_start, new_end, fragment.nullable)
      when '?'
        # Zero or one
        new_start = create_nfa_state(counter, states)
        new_end = create_nfa_state(counter, states)

        new_start.add_transition(nil, frag_start)
        new_start.add_transition(nil, new_end)
        frag_end.add_transition(nil, new_end)

        Fragment.new(new_start, new_end, true)
      else
        fragment
      end
    end

    # @rbs (Array[Fragment] fragments, Array[Integer] counter, Array[NFAState] states) -> Fragment
    def alternate_fragments(fragments, counter, states)
      return fragments.first if fragments.size == 1

      alt_start = create_nfa_state(counter, states)
      alt_end = create_nfa_state(counter, states)

      fragments.each do |fragment|
        alt_start.add_transition(nil, fragment.start_state)
        fragment.end_state.add_transition(nil, alt_end)
      end

      Fragment.new(alt_start, alt_end, fragments.any?(&:nullable))
    end

    # Concatenate multiple NFA fragments into one
    # @rbs (Array[Fragment] fragments, Array[Integer] counter, Array[NFAState] states) -> Fragment
    def concatenate_fragments(fragments, counter, states)
      raise PatternError, "empty sequences are not allowed" if fragments.empty?
      return fragments.first if fragments.size == 1

      result_start = fragments.first.start_state
      current_end = fragments.first.end_state
      nullable = fragments.all?(&:nullable)

      fragments[1..-1].each do |fragment|
        current_end.add_transition(nil, fragment.start_state)
        current_end = fragment.end_state
      end

      Fragment.new(result_start, current_end, nullable)
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
