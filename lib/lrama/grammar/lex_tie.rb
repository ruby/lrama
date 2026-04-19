# rbs_inline: enabled
# frozen_string_literal: true

require "set"

module Lrama
  class Grammar
    # Stores PSLR lexical ties and explicit no-tie declarations.
    #
    # Lexical ties expand acc(sp); they never resolve a scanner conflict by
    # themselves. Conflict selection is still handled by %lex-prec.
    class LexTie
      attr_reader :ties #: Hash[String, Set[String]]
      attr_reader :no_ties #: Set[[String, String]]

      # @rbs () -> void
      def initialize
        @ties = Hash.new { |h, k| h[k] = Set.new([k]) }
        @no_ties = Set.new
      end

      # @rbs (String left, String right) -> void
      def add_tie(left, right)
        left_set = tied_names(left)
        right_set = tied_names(right)
        merged = left_set | right_set

        merged.each do |name|
          @ties[name] = merged.dup
        end
      end

      # @rbs (String left, String right) -> void
      def add_no_tie(left, right)
        @no_ties << pair_key(left, right)
      end

      # @rbs (String name) -> Set[String]
      def tied_names(name)
        @ties[name].dup
      end

      # @rbs (String left, String right) -> bool
      def tied?(left, right)
        tied_names(left).include?(right)
      end

      # @rbs (String left, String right) -> bool
      def no_tie?(left, right)
        @no_ties.include?(pair_key(left, right))
      end

      # @rbs () -> Array[[String, String]]
      def no_ties_conflicting_with_ties
        @no_ties.select do |left, right|
          tied?(left, right)
        end
      end

      private

      # @rbs (String left, String right) -> [String, String]
      def pair_key(left, right)
        left <= right ? [left, right] : [right, left]
      end
    end
  end
end
