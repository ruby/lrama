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

      class ProfileOutcome
        EMPTY = :empty #: Symbol
        RESOLVED = :resolved #: Symbol
        UNRESOLVED = :unresolved #: Symbol

        attr_reader :kind #: Symbol
        attr_reader :token_name #: String?
        attr_reader :conflict #: Conflict?

        # @rbs (kind: Symbol, ?token_name: String?, ?conflict: Conflict?) -> void
        def initialize(kind:, token_name: nil, conflict: nil)
          @kind = kind
          @token_name = token_name
          @conflict = conflict
        end

        # @rbs () -> bool
        def empty?
          @kind == EMPTY
        end

        # @rbs () -> bool
        def resolved?
          @kind == RESOLVED
        end

        # @rbs () -> bool
        def unresolved?
          @kind == UNRESOLVED
        end
      end

      class ProfileResolver
        # @rbs (Grammar::LexPrec lex_prec, LengthPrecedences length_prec, ?fallback: bool, ?token_order: Hash[String, Integer]) -> void
        def initialize(lex_prec, length_prec, fallback: false, token_order: {})
          @lex_prec = lex_prec
          @length_prec = length_prec
          @fallback = fallback
          @token_order = token_order
        end

        # @rbs (Set[String] shorter_tokens, String? selected_shorter_token, Set[String] current_tokens) -> ProfileOutcome
        def resolve(shorter_tokens, selected_shorter_token, current_tokens)
          if @fallback
            resolve_fallback(shorter_tokens, selected_shorter_token, current_tokens)
          else
            resolve_normal(shorter_tokens, selected_shorter_token, current_tokens)
          end
        end

        private

        # @rbs (Set[String] shorter_tokens, String? selected_shorter_token, Set[String] current_tokens) -> ProfileOutcome
        def resolve_normal(shorter_tokens, selected_shorter_token, current_tokens)
          if current_tokens.empty?
            return ProfileOutcome.new(kind: ProfileOutcome::RESOLVED, token_name: selected_shorter_token) if selected_shorter_token

            return ProfileOutcome.new(kind: ProfileOutcome::EMPTY)
          end

          if selected_shorter_token && current_tokens.all? {|token| length_prefers_old?(selected_shorter_token, token) }
            return ProfileOutcome.new(kind: ProfileOutcome::RESOLVED, token_name: selected_shorter_token)
          end

          winners = current_tokens.select do |candidate|
            identity_winner?(candidate, current_tokens) &&
              shorter_tokens.all? {|shorter| @length_prec.resolution(shorter, candidate) == LengthPrecedences::PREFER_NEW }
          end

          return ProfileOutcome.new(kind: ProfileOutcome::RESOLVED, token_name: winners.first) if winners.size == 1

          ProfileOutcome.new(kind: ProfileOutcome::UNRESOLVED)
        end

        # @rbs (Set[String] shorter_tokens, String? selected_shorter_token, Set[String] current_tokens) -> ProfileOutcome
        def resolve_fallback(shorter_tokens, selected_shorter_token, current_tokens)
          if current_tokens.empty?
            return ProfileOutcome.new(kind: ProfileOutcome::RESOLVED, token_name: selected_shorter_token) if selected_shorter_token

            return ProfileOutcome.new(kind: ProfileOutcome::EMPTY)
          end

          if selected_shorter_token && current_tokens.all? {|token| fallback_length_prefers_old?(selected_shorter_token, token) }
            return ProfileOutcome.new(kind: ProfileOutcome::RESOLVED, token_name: selected_shorter_token)
          end

          winners = current_tokens.select do |candidate|
            fallback_identity_winner?(candidate, current_tokens) &&
              shorter_tokens.all? {|shorter| @length_prec.fallback_precedes?(shorter, candidate) }
          end

          return ProfileOutcome.new(kind: ProfileOutcome::RESOLVED, token_name: winners.first) if winners.size == 1

          ProfileOutcome.new(kind: ProfileOutcome::UNRESOLVED)
        end

        # @rbs (String old_token, String new_token) -> bool
        def length_prefers_old?(old_token, new_token)
          @length_prec.resolution(old_token, new_token) == LengthPrecedences::PREFER_OLD
        end

        # @rbs (String old_token, String new_token) -> bool
        def fallback_length_prefers_old?(old_token, new_token)
          !@length_prec.fallback_precedes?(old_token, new_token)
        end

        # @rbs (String candidate, Set[String] current_tokens) -> bool
        def identity_winner?(candidate, current_tokens)
          current_tokens.all? do |other|
            candidate == other || @lex_prec.identity_precedes?(candidate, other)
          end
        end

        # @rbs (String candidate, Set[String] current_tokens) -> bool
        def fallback_identity_winner?(candidate, current_tokens)
          current_tokens.all? do |other|
            next true if candidate == other

            candidate_wins = @lex_prec.identity_precedes?(candidate, other)
            other_wins = @lex_prec.identity_precedes?(other, candidate)
            if candidate_wins && !other_wins
              true
            elsif other_wins
              false
            else
              token_order_precedes?(candidate, other)
            end
          end
        end

        # @rbs (String candidate, String other) -> bool
        def token_order_precedes?(candidate, other)
          (token_order_key(candidate) <=> token_order_key(other)) == -1
        end

        # @rbs (String token) -> [Integer, String]
        def token_order_key(token)
          [@token_order.fetch(token, @token_order.size), token]
        end
      end

      class CompleteProfileComputer
        attr_reader :table #: Hash[Integer, Grammar::TokenPattern]
        attr_reader :conflicts #: Array[Conflict]

        # @rbs (ScannerFSA scanner_fsa, Grammar::LexPrec lex_prec, LengthPrecedences length_prec, Set[String] acceptable_tokens, ?Integer? parser_state_id, ?fallback: bool, ?token_order: Hash[String, Integer]) -> void
        def initialize(scanner_fsa, lex_prec, length_prec, acceptable_tokens, parser_state_id = nil, fallback: false, token_order: {})
          @scanner_fsa = scanner_fsa
          @resolver = ProfileResolver.new(lex_prec, length_prec, fallback: fallback, token_order: token_order)
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
          result = @resolver.resolve(shorter_tokens, selected_shorter_token, current_tokens)

          if result.resolved?
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
          elsif result.unresolved?
            @conflicts << Conflict.new(
              parser_state_id: @parser_state_id,
              scanner_state_id: fsa_state_id,
              shorter_tokens: shorter_tokens.to_a.sort,
              selected_shorter_token: selected_shorter_token,
              current_tokens: current_tokens.to_a.sort
            )
          end

          next_shorter_tokens = shorter_tokens | current_tokens
          next_selected = result.resolved? ? result.token_name : nil
          visit_transitions(fsa_state_id, next_shorter_tokens, next_selected, visited)
        end

        # @rbs (ScannerFSA::State fsa_state) -> Set[String]
        def current_acceptable_tokens(fsa_state)
          fsa_state.accepting_tokens.each_with_object(Set.new) do |token_pattern, tokens|
            tokens << token_pattern.name if @acceptable_tokens.include?(token_pattern.name)
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

      class CompatibilityChecker
        # @rbs (ScannerFSA scanner_fsa, Grammar::LexPrec lex_prec, LengthPrecedences length_prec) -> void
        def initialize(scanner_fsa, lex_prec, length_prec)
          @scanner_fsa = scanner_fsa
          @resolver = ProfileResolver.new(lex_prec, length_prec)
        end

        # @rbs (Set[String] left_tokens, Set[String] right_tokens) -> bool
        def compatible?(left_tokens, right_tokens)
          visit_transitions(0, Set.new, nil, Set.new, nil, left_tokens, right_tokens, Set.new)
        end

        private

        # @rbs (Integer fsa_state_id, Set[String] left_shorter, String? left_selected, Set[String] right_shorter, String? right_selected, Set[String] left_acc, Set[String] right_acc, Set[untyped] visited) -> bool
        def visit_transitions(fsa_state_id, left_shorter, left_selected, right_shorter, right_selected, left_acc, right_acc, visited)
          fsa_state = @scanner_fsa.states[fsa_state_id]
          return true unless fsa_state

          fsa_state.transitions.each_value do |next_state_id|
            return false unless visit_state(next_state_id, left_shorter, left_selected, right_shorter, right_selected, left_acc, right_acc, visited)
          end

          true
        end

        # @rbs (Integer fsa_state_id, Set[String] left_shorter, String? left_selected, Set[String] right_shorter, String? right_selected, Set[String] left_acc, Set[String] right_acc, Set[untyped] visited) -> bool
        def visit_state(fsa_state_id, left_shorter, left_selected, right_shorter, right_selected, left_acc, right_acc, visited)
          fsa_state = @scanner_fsa.states[fsa_state_id]
          return true unless fsa_state

          left_current = tokens_accepted_by(fsa_state, left_acc)
          right_current = tokens_accepted_by(fsa_state, right_acc)
          left_outcome = @resolver.resolve(left_shorter, left_selected, left_current)
          right_outcome = @resolver.resolve(right_shorter, right_selected, right_current)

          return false unless outcomes_compatible?(left_outcome, right_outcome)

          key = [
            fsa_state_id,
            left_shorter.to_a.sort,
            left_outcome.kind,
            left_outcome.token_name,
            right_shorter.to_a.sort,
            right_outcome.kind,
            right_outcome.token_name
          ]
          return true if visited.include?(key)

          visited << key

          visit_transitions(
            fsa_state_id,
            left_shorter | left_current,
            left_outcome.resolved? ? left_outcome.token_name : nil,
            right_shorter | right_current,
            right_outcome.resolved? ? right_outcome.token_name : nil,
            left_acc,
            right_acc,
            visited
          )
        end

        # @rbs (ScannerFSA::State fsa_state, Set[String] accepted_names) -> Set[String]
        def tokens_accepted_by(fsa_state, accepted_names)
          fsa_state.accepting_tokens.each_with_object(Set.new) do |token_pattern, tokens|
            tokens << token_pattern.name if accepted_names.include?(token_pattern.name)
          end
        end

        # @rbs (ProfileOutcome left, ProfileOutcome right) -> bool
        def outcomes_compatible?(left, right)
          return true if left.empty? || right.empty?
          return true if left.unresolved? && right.unresolved?
          return false if left.unresolved? || right.unresolved?

          left.token_name == right.token_name
        end
      end

      FALLBACK_ROW_ID = -1 #: Integer

      attr_reader :table #: Hash[[Integer, Integer], Grammar::TokenPattern?]
      attr_reader :fallback_table #: Hash[Integer, Grammar::TokenPattern]
      attr_reader :conflicts #: Array[Conflict]

      # @rbs (Array[State] parser_states, ScannerFSA scanner_fsa, Grammar::LexPrec lex_prec, LengthPrecedences length_prec, ?Grammar::LexTie? lex_tie, ?layout_token_names: Set[String]) -> void
      def initialize(parser_states, scanner_fsa, lex_prec, length_prec, lex_tie = nil, layout_token_names: Set.new)
        @parser_states = parser_states
        @scanner_fsa = scanner_fsa
        @lex_prec = lex_prec
        @length_prec = length_prec
        @lex_tie = lex_tie
        @layout_token_names = layout_token_names.to_set
        @table = {}
        @fallback_table = {}
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
        compute_fallback_row
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

      # @rbs () -> void
      def compute_fallback_row
        all_tokens = @scanner_fsa.token_patterns.map(&:name).to_set
        computer = CompleteProfileComputer.new(
          @scanner_fsa,
          @lex_prec,
          @length_prec,
          all_tokens,
          FALLBACK_ROW_ID,
          fallback: true,
          token_order: token_order
        )
        computer.compute

        computer.table.each do |scanner_state_id, token_pattern|
          @fallback_table[scanner_state_id] = token_pattern
          @table[[FALLBACK_ROW_ID, scanner_state_id]] = token_pattern
        end
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

        expand_lexical_ties(tokens) | @layout_token_names
      end

      # @rbs (Set[String] tokens) -> Set[String]
      def expand_lexical_ties(tokens)
        return tokens unless @lex_tie

        tokens.each_with_object(Set.new) do |token, expanded|
          @lex_tie.tied_names(token).each {|name| expanded << name }
        end
      end

      # @rbs () -> Hash[String, Integer]
      def token_order
        initial = {} #: Hash[String, Integer]
        @scanner_fsa.token_patterns.each_with_object(initial) do |token_pattern, order|
          order[token_pattern.name] ||= token_pattern.definition_order
        end
      end
    end
  end
end
