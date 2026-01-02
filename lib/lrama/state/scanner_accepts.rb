# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class State
    # Scanner accepts table for PSLR(1)
    # Based on Definition 3.2.14 from the PSLR dissertation
    #
    # scanner_accepts[sp, sa]: For parser state sp and accepting state sa,
    # returns the token that should be selected
    class ScannerAccepts
      attr_reader :table #: Hash[[Integer, Integer], Grammar::TokenPattern?]

      # @rbs (Array[State] parser_states, ScannerFSA scanner_fsa, Grammar::LexPrec lex_prec, LengthPrecedences length_prec) -> void
      def initialize(parser_states, scanner_fsa, lex_prec, length_prec)
        @parser_states = parser_states
        @scanner_fsa = scanner_fsa
        @lex_prec = lex_prec
        @length_prec = length_prec
        @table = {}
        @profile_map = {} #: Hash[untyped, untyped] # Cache for conflict profile resolution
      end

      # Build the scanner_accepts table
      # Based on Definition 3.2.20 (compute_scanner_accepts)
      # @rbs () -> void
      def build
        @parser_states.each do |parser_state|
          compute_for_parser_state(parser_state)
        end
      end

      # Get the accepted token for a parser state and accepting state
      # @rbs (Integer parser_state_id, Integer accepting_state_id) -> Grammar::TokenPattern?
      def [](parser_state_id, accepting_state_id)
        @table[[parser_state_id, accepting_state_id]]
      end

      private

      # Compute scanner_accepts for a single parser state
      # Uses DFS to explore the FSA state space
      # @rbs (State parser_state) -> void
      def compute_for_parser_state(parser_state)
        visited = Set.new
        dfs(parser_state, 0, visited) # Start from FSA initial state (id 0)
      end

      # DFS exploration of FSA states
      # @rbs (State parser_state, Integer fsa_state_id, Set[Integer] visited) -> void
      def dfs(parser_state, fsa_state_id, visited)
        return if visited.include?(fsa_state_id)
        visited << fsa_state_id

        fsa_state = @scanner_fsa.states[fsa_state_id]
        return unless fsa_state

        # If this is an accepting state, compute the accepted token
        if fsa_state.accepting?
          token = resolve(parser_state, fsa_state)
          @table[[parser_state.id, fsa_state_id]] = token if token
        end

        # Explore transitions
        fsa_state.transitions.each_value do |next_state_id|
          dfs(parser_state, next_state_id, visited)
        end
      end

      # Resolve which token should be accepted
      # Based on Definition 3.2.19 (resolve)
      # @rbs (State parser_state, ScannerFSA::State fsa_state) -> Grammar::TokenPattern?
      def resolve(parser_state, fsa_state)
        # Get tokens that are both:
        # 1. Accepted by the FSA at this state (acc(ss))
        # 2. Accepted by the parser at this state (acc(sp))
        acc_ss = fsa_state.accepting_tokens
        acc_sp = compute_acc_sp(parser_state)

        # Intersection: tokens that can be both scanned and parsed
        acc_sp_ss = acc_ss.select do |token_pattern|
          acc_sp.include?(token_pattern.name)
        end

        return nil if acc_sp_ss.empty?

        # Select the highest priority token
        select_best_token(acc_sp_ss)
      end

      # Compute acc(sp): set of terminal symbols acceptable at parser state sp
      # @rbs (State parser_state) -> Set[String]
      def compute_acc_sp(parser_state)
        tokens = Set.new

        # Add tokens from shift actions (term_transitions)
        parser_state.term_transitions.each do |shift|
          next_sym = shift.next_sym
          tokens << next_sym.id.s_value if next_sym.term?
        end

        # Add tokens from reduce actions (lookahead)
        parser_state.reduces.each do |reduce|
          reduce.look_ahead&.each do |la|
            tokens << la.id.s_value
          end
        end

        tokens
      end

      # Select the best token from candidates based on precedence rules
      # @rbs (Array[Grammar::TokenPattern] candidates) -> Grammar::TokenPattern?
      def select_best_token(candidates)
        return candidates.first if candidates.size <= 1

        # Sort by:
        # 1. Explicit precedence (from %lex-prec - rules)
        # 2. Definition order (first defined wins)
        candidates.min_by do |token|
          priority_rank(token, candidates)
        end
      end

      # Compute priority rank for a token among candidates
      # Lower rank = higher priority
      # @rbs (Grammar::TokenPattern token, Array[Grammar::TokenPattern] candidates) -> [Integer, Integer]
      def priority_rank(token, candidates)
        # Check if this token has explicit higher priority over others
        higher_count = candidates.count do |other|
          next false if other == token
          @lex_prec.higher_priority?(token.name, other.name)
        end

        # Tokens with more "higher than" relationships get lower rank
        # Fallback to definition order
        [-higher_count, token.definition_order]
      end
    end
  end
end
