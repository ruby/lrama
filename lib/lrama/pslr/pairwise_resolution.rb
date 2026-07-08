# rbs_inline: enabled
# frozen_string_literal: true

require "set"

module Lrama
  module Pslr
    # Pair-based PSLR state compatibility (paper section 3.4.3).
    #
    # The scanner FSA is scanned once to find every token pair that can be
    # in an identity or length scanner conflict. Two acceptable-token sets
    # are then compatible when no conflict pair distinguishes them:
    #
    # * both sets contain the same subset of the pair (the pseudo-scanner
    #   resolves the conflict identically, or leaves it identically
    #   unresolved -- unresolved/unresolved states merge), or
    # * one set contains neither token of the pair (its match set for
    #   inputs manifesting the conflict is empty for this pair).
    #
    # Reducing the check to pairs is the precomputation the paper
    # recommends for phase 3: the per-pair verdict no longer depends on
    # the rest of the accept set, so state splitting does not have to
    # re-run the profile resolver for every candidate merge. Layout
    # tokens are members of every accept set, so pairs won by layout can
    # never distinguish two states (the split-stable layout optimization
    # of section 3.6 falls out of the presence test).
    class PairwiseResolution
      attr_reader :conflict_pairs #: Set[[String, String]]

      # @rbs (ScannerFSA scanner_fsa) -> void
      def initialize(scanner_fsa)
        @conflict_pairs = scanner_fsa.pairwise_conflict_pairs
        pairs_by_token = Hash.new {|h, k| h[k] = [] } #: Hash[String, Array[[String, String]]]
        @pairs_by_token = @conflict_pairs.each_with_object(pairs_by_token) do |pair, hash|
          hash[pair[0]] << pair
          hash[pair[1]] << pair
        end
      end

      # @rbs (Set[String] left_acc, Set[String] right_acc) -> bool
      def compatible_accept_sets?(left_acc, right_acc)
        return true if left_acc == right_acc

        # Only conflict pairs touching the symmetric difference can
        # distinguish the two accept sets.
        diff = (left_acc - right_acc) | (right_acc - left_acc)
        return true if diff.empty?

        checked = Set.new #: Set[[String, String]]
        diff.all? do |token|
          @pairs_by_token[token].all? do |pair|
            next true unless checked.add?(pair)

            pair_compatible?(pair, left_acc, right_acc)
          end
        end
      end

      private

      # @rbs ([String, String] pair, Set[String] left_acc, Set[String] right_acc) -> bool
      def pair_compatible?(pair, left_acc, right_acc)
        left_presence = presence(pair, left_acc)
        right_presence = presence(pair, right_acc)

        left_presence == right_presence || left_presence == 0 || right_presence == 0
      end

      # @rbs ([String, String] pair, Set[String] acc) -> Integer
      def presence(pair, acc)
        (acc.include?(pair[0]) ? 1 : 0) | (acc.include?(pair[1]) ? 2 : 0)
      end
    end
  end
end
