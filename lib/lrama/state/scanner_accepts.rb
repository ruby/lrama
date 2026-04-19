# rbs_inline: enabled
# frozen_string_literal: true

require "set"

module Lrama
  class State
    # scanner_accepts[parser_state, accepting_scanner_state] for PSLR(1).
    #
    # Construction follows complete pseudo-scanner conflict profiles. A profile
    # contains the shorter token set Ts, the selected shorter token ts, and the
    # current/longest token set Tl. Ambiguities remain unresolved; declaration
    # order is never used as a fallback.
    class ScannerAccepts
      class Conflict
        attr_reader :parser_state_id #: Integer?
        attr_reader :scanner_state_id #: Integer
        attr_reader :shorter_tokens #: Array[String]
        attr_reader :selected_shorter_token #: String?
        attr_reader :current_tokens #: Array[String]

        # @rbs (parser_state_id: Integer?, scanner_state_id: Integer, shorter_tokens: Array[String], selected_shorter_token: String?, current_tokens: Array[String]) -> void
        def initialize(parser_state_id:, scanner_state_id:, shorter_tokens:, selected_shorter_token:, current_tokens:)
          @parser_state_id = parser_state_id
          @scanner_state_id = scanner_state_id
          @shorter_tokens = shorter_tokens
          @selected_shorter_token = selected_shorter_token
          @current_tokens = current_tokens
        end
      end

      class Result
        attr_reader :resolved #: bool
        attr_reader :token_name #: String?

        # @rbs (resolved: bool, token_name: String?) -> void
        def initialize(resolved:, token_name:)
          @resolved = resolved
          @token_name = token_name
        end
      end

      class CompleteProfileComputer
        attr_reader :table #: Hash[Integer, Grammar::TokenPattern]
        attr_reader :conflicts #: Array[Conflict]

        # @rbs (ScannerFSA scanner_fsa, Grammar::LexPrec lex_prec, LengthPrecedences length_prec, Set[String] acceptable_tokens, ?Integer? parser_state_id) -> void
        def initialize(scanner_fsa, lex_prec, length_prec, acceptable_tokens, parser_state_id = nil)
          @scanner_fsa = scanner_fsa
          @lex_prec = lex_prec
          @length_prec = length_prec
          @acceptable_tokens = acceptable_tokens
          @parser_state_id = parser_state_id
          @table = {}
          @conflicts = []
          token_patterns_by_name = {} #: Hash[String, Grammar::TokenPattern]
          @token_patterns_by_name = scanner_fsa.token_patterns.each_with_object(token_patterns_by_name) do |token_pattern, hash|
            hash[token_pattern.name] ||= token_pattern
          end
        end

        # @rbs () -> void
        def compute
          visited = Set.new
          visit_transitions(0, Set.new, nil, visited)
        end

        private

        # @rbs (Integer fsa_state_id, Set[String] shorter_tokens, String? selected_shorter_token, Set[untyped] visited) -> void
        def visit_transitions(fsa_state_id, shorter_tokens, selected_shorter_token, visited)
          fsa_state = @scanner_fsa.states[fsa_state_id]
          return unless fsa_state

          fsa_state.transitions.each_value do |next_state_id|
            visit_state(next_state_id, shorter_tokens, selected_shorter_token, visited)
          end
        end

        # @rbs (Integer fsa_state_id, Set[String] shorter_tokens, String? selected_shorter_token, Set[untyped] visited) -> void
        def visit_state(fsa_state_id, shorter_tokens, selected_shorter_token, visited)
          fsa_state = @scanner_fsa.states[fsa_state_id]
          return unless fsa_state

          current_tokens = current_acceptable_tokens(fsa_state)
          key = profile_key(fsa_state_id, shorter_tokens, selected_shorter_token, current_tokens)
          return if visited.include?(key)

          visited << key
          result = resolve_profile(shorter_tokens, selected_shorter_token, current_tokens)

          if result.resolved
            if result.token_name && current_tokens.include?(result.token_name)
              token_pattern = token_pattern_for(result.token_name)
              existing = @table[fsa_state_id]
              if existing && existing.name != token_pattern.name
                @conflicts << Conflict.new(
                  parser_state_id: @parser_state_id,
                  scanner_state_id: fsa_state_id,
                  shorter_tokens: shorter_tokens.to_a.sort,
                  selected_shorter_token: existing.name,
                  current_tokens: current_tokens.to_a.sort
                )
              else
                @table[fsa_state_id] = token_pattern
              end
            end
          else
            @conflicts << Conflict.new(
              parser_state_id: @parser_state_id,
              scanner_state_id: fsa_state_id,
              shorter_tokens: shorter_tokens.to_a.sort,
              selected_shorter_token: selected_shorter_token,
              current_tokens: current_tokens.to_a.sort
            )
          end

          next_shorter_tokens = shorter_tokens | current_tokens
          next_selected = result.resolved ? result.token_name : nil
          visit_transitions(fsa_state_id, next_shorter_tokens, next_selected, visited)
        end

        # @rbs (ScannerFSA::State fsa_state) -> Set[String]
        def current_acceptable_tokens(fsa_state)
          fsa_state.accepting_tokens.each_with_object(Set.new) do |token_pattern, tokens|
            tokens << token_pattern.name if @acceptable_tokens.include?(token_pattern.name)
          end
        end

        # @rbs (Set[String] shorter_tokens, String? selected_shorter_token, Set[String] current_tokens) -> Result
        def resolve_profile(shorter_tokens, selected_shorter_token, current_tokens)
          return Result.new(resolved: true, token_name: selected_shorter_token) if current_tokens.empty?

          if selected_shorter_token && current_tokens.all? {|token| length_prefers_old?(selected_shorter_token, token) }
            return Result.new(resolved: true, token_name: selected_shorter_token)
          end

          winners = current_tokens.select do |candidate|
            identity_winner?(candidate, current_tokens) &&
              shorter_tokens.all? {|shorter| @length_prec.resolution(shorter, candidate) == LengthPrecedences::PREFER_NEW }
          end

          return Result.new(resolved: true, token_name: winners.first) if winners.size == 1

          Result.new(resolved: false, token_name: nil)
        end

        # @rbs (String old_token, String new_token) -> bool
        def length_prefers_old?(old_token, new_token)
          @length_prec.resolution(old_token, new_token) == LengthPrecedences::PREFER_OLD
        end

        # @rbs (String candidate, Set[String] current_tokens) -> bool
        def identity_winner?(candidate, current_tokens)
          current_tokens.all? do |other|
            candidate == other || @lex_prec.identity_precedes?(candidate, other)
          end
        end

        # @rbs (String token_name) -> Grammar::TokenPattern
        def token_pattern_for(token_name)
          @token_patterns_by_name.fetch(token_name)
        end

        # @rbs (Integer fsa_state_id, Set[String] shorter_tokens, String? selected_shorter_token, Set[String] current_tokens) -> [Integer, Array[String], String?, Array[String]]
        def profile_key(fsa_state_id, shorter_tokens, selected_shorter_token, current_tokens)
          [fsa_state_id, shorter_tokens.to_a.sort, selected_shorter_token, current_tokens.to_a.sort]
        end
      end

      attr_reader :table #: Hash[[Integer, Integer], Grammar::TokenPattern?]
      attr_reader :conflicts #: Array[Conflict]

      # @rbs (Array[State] parser_states, ScannerFSA scanner_fsa, Grammar::LexPrec lex_prec, LengthPrecedences length_prec, ?Grammar::LexTie? lex_tie) -> void
      def initialize(parser_states, scanner_fsa, lex_prec, length_prec, lex_tie = nil)
        @parser_states = parser_states
        @scanner_fsa = scanner_fsa
        @lex_prec = lex_prec
        @length_prec = length_prec
        @lex_tie = lex_tie
        @table = {}
        @conflicts = []
      end

      # @rbs (ScannerFSA scanner_fsa, Grammar::LexPrec lex_prec, LengthPrecedences length_prec, Set[String] acceptable_tokens) -> [Hash[Integer, Grammar::TokenPattern], Array[Conflict]]
      def self.compute_for_acceptable_tokens(scanner_fsa, lex_prec, length_prec, acceptable_tokens)
        computer = CompleteProfileComputer.new(scanner_fsa, lex_prec, length_prec, acceptable_tokens)
        computer.compute
        [computer.table, computer.conflicts]
      end

      # @rbs () -> void
      def build
        @parser_states.each do |parser_state|
          compute_for_parser_state(parser_state)
        end
      end

      # @rbs (Integer parser_state_id, Integer accepting_state_id) -> Grammar::TokenPattern?
      def [](parser_state_id, accepting_state_id)
        @table[[parser_state_id, accepting_state_id]]
      end

      # @rbs () -> bool
      def unresolved_conflicts?
        !@conflicts.empty?
      end

      private

      # @rbs (State parser_state) -> void
      def compute_for_parser_state(parser_state)
        computer = CompleteProfileComputer.new(
          @scanner_fsa,
          @lex_prec,
          @length_prec,
          compute_acc_sp(parser_state),
          parser_state.id
        )
        computer.compute

        computer.table.each do |scanner_state_id, token_pattern|
          @table[[parser_state.id, scanner_state_id]] = token_pattern
        end
        @conflicts.concat(computer.conflicts)
      end

      # @rbs (State parser_state) -> Set[String]
      def compute_acc_sp(parser_state)
        tokens = Set.new

        parser_state.term_transitions.each do |shift|
          next_sym = shift.next_sym
          tokens << next_sym.id.s_value if next_sym.term?
        end

        parser_state.reduces.each do |reduce|
          parser_state.acceptable_pslr_reduce_lookahead(reduce).each do |la|
            tokens << la.id.s_value
          end
        end

        expand_lexical_ties(tokens)
      end

      # @rbs (Set[String] tokens) -> Set[String]
      def expand_lexical_ties(tokens)
        return tokens unless @lex_tie

        tokens.each_with_object(Set.new) do |token, expanded|
          @lex_tie.tied_names(token).each {|name| expanded << name }
        end
      end
    end
  end
end
