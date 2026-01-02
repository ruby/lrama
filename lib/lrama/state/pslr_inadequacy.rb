# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class State
    # PSLR Inadequacy detection
    # Based on Section 3.4.3 from the PSLR dissertation
    #
    # PSLR inadequacy occurs when state merging causes different
    # pseudo-scanner behavior
    class PslrInadequacy
      # Inadequacy types
      LR_RELATIVE = :lr_relative      #: Symbol
      PSLR_RELATIVE = :pslr_relative  #: Symbol

      attr_reader :type #: Symbol
      attr_reader :state #: State
      attr_reader :conflicting_states #: Array[State]
      attr_reader :details #: Hash[Symbol, Object]

      # @rbs (type: Symbol, state: State, conflicting_states: Array[State], details: Hash[Symbol, untyped]) -> void
      def initialize(type:, state:, conflicting_states:, details:)
        @type = type
        @state = state
        @conflicting_states = conflicting_states
        @details = details
      end

      # @rbs () -> String
      def to_s
        "PSLR Inadequacy (#{type}): state #{state.id} conflicts with states #{conflicting_states.map(&:id).join(', ')}"
      end
    end

    # PSLR Compatibility checker
    # Based on Definition 3.4.1 from the dissertation
    class PslrCompatibilityChecker
      # @rbs (ScannerAccepts scanner_accepts, LengthPrecedences length_prec) -> void
      def initialize(scanner_accepts, length_prec)
        @scanner_accepts = scanner_accepts
        @length_prec = length_prec
      end

      # Check if two states are PSLR-compatible
      # Definition 3.4.1: States are compatible if for any input,
      # the pseudo-scanner selects the same token
      # @rbs (State s1, State s2, ScannerFSA scanner_fsa) -> bool
      def compatible?(s1, s2, scanner_fsa)
        # For all accepting states in the FSA, check if the selected tokens match
        scanner_fsa.states.each do |fsa_state|
          next unless fsa_state.accepting?

          token1 = @scanner_accepts[s1.id, fsa_state.id]
          token2 = @scanner_accepts[s2.id, fsa_state.id]

          # Both undefined is compatible
          next if token1.nil? && token2.nil?

          # Different tokens are incompatible
          return false if token1 != token2
        end

        true
      end
    end
  end
end
