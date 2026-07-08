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
      attr_reader :details #: Hash[Symbol, untyped]

      # @rbs (type: Symbol, state: State, conflicting_states: Array[State], details: Hash[Symbol, untyped]) -> void
      def initialize(type:, state:, conflicting_states:, details:)
        @type = type
        @state = state
        @conflicting_states = conflicting_states
        @details = details
      end

      # @rbs () -> String
      def to_s
        message = "PSLR Inadequacy (#{type}): state #{state.id} conflicts with states #{conflicting_states.map(&:id).join(', ')}"
        return message if details[:profiles].nil?

        profiles = details[:profiles].map do |profile, state_ids|
          "#{state_ids.join(', ')} => #{profile.inspect}"
        end

        "#{message} (profiles: #{profiles.join(' | ')})"
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

      # Build a stable scanner profile for a parser state
      # @rbs (State state, ScannerFSA scanner_fsa) -> Array[[Integer, String?]]
      def profile(state, scanner_fsa)
        scanner_fsa.states.each_with_object([]) do |fsa_state, result|
          next unless fsa_state.accepting?

          token = @scanner_accepts[state.id, fsa_state.id]
          result << [fsa_state.id, token&.name]
        end
      end

      # Partition states by scanner profile
      # @rbs (Array[State] states, ScannerFSA scanner_fsa) -> Hash[Array[[Integer, String?]], Array[State]]
      def group_by_profile(states, scanner_fsa)
        states.group_by do |state|
          profile(state, scanner_fsa)
        end
      end

      # Check if two states are PSLR-compatible
      # Definition 3.4.1: States are compatible if for any input,
      # the pseudo-scanner selects the same token
      # @rbs (State s1, State s2, ScannerFSA scanner_fsa) -> bool
      def compatible?(s1, s2, scanner_fsa)
        profile(s1, scanner_fsa) == profile(s2, scanner_fsa)
      end
    end
  end
end
