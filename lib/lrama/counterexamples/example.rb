# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Counterexamples
    class Example
      # TODO: rbs-inline 0.10.0 doesn't support instance variables.
      #       Move these type declarations above instance variable definitions, once it's supported.
      #
      # @rbs!
      #   @path1: ::Array[Path::path]
      #   @path2: ::Array[Path::path]
      #   @conflict: State::conflict
      #   @conflict_symbol: Grammar::Symbol
      #   @counterexamples: Counterexamples
      #   @derivations1: Derivation
      #   @derivations2: Derivation

      attr_reader :path1 #: ::Array[Path::path]
      attr_reader :path2 #: ::Array[Path::path]
      attr_reader :conflict #: State::conflict
      attr_reader :conflict_symbol #: Grammar::Symbol

      # path1 is shift conflict when S/R conflict
      # path2 is always reduce conflict
      #
      # @rbs (::Array[Path::path]? path1, ::Array[Path::path]? path2, State::conflict conflict, Grammar::Symbol conflict_symbol, Counterexamples counterexamples) -> void
      def initialize(path1, path2, conflict, conflict_symbol, counterexamples)
        @path1 = path1
        @path2 = path2
        @conflict = conflict
        @conflict_symbol = conflict_symbol
        @counterexamples = counterexamples
      end

      # @rbs () -> (:shift_reduce | :reduce_reduce)
      def type
        @conflict.type
      end

      # @rbs () -> States::Item
      def path1_item
        @path1.last.state_item.item
      end

      # @rbs () -> States::Item
      def path2_item
        @path2.last.state_item.item
      end

      # @rbs () -> Derivation
      def derivations1
        @derivations1 ||= _derivations(path1)
      end

      # @rbs () -> Derivation
      def derivations2
        @derivations2 ||= _derivations(path2)
      end

      private

      # @rbs (::Array[Path::path] paths) -> Derivation
      def _derivations(paths)
        derivation = nil #: Derivation
        current = :production
        last_path = paths.last #: Path
        lookahead_sym = last_path.state_item.item.end_of_rule? ? @conflict_symbol : nil

        paths.reverse_each do |path|
          item = path.state_item.item

          case current
          when :production
            case path
            when StartPath
              derivation = Derivation.new(item, derivation)
              current = :start
            when TransitionPath
              derivation = Derivation.new(item, derivation)
              current = :transition
            when ProductionPath
              derivation = Derivation.new(item, derivation)
              current = :production
            else
              raise "Unexpected. #{path}"
            end

            if lookahead_sym && item.next_next_sym && item.next_next_sym.first_set.include?(lookahead_sym)
              state_item = @counterexamples.transitions[[path.state_item, item.next_sym]]
              derivation2 = find_derivation_for_symbol(state_item, lookahead_sym)
              derivation.right = derivation2 # steep:ignore
              lookahead_sym = nil
            end

          when :transition
            case path
            when StartPath
              derivation = Derivation.new(item, derivation)
              current = :start
            when TransitionPath
              # ignore
              current = :transition
            when ProductionPath
              # ignore
              current = :production
            end
          else
            raise "BUG: Unknown #{current}"
          end

          break if current == :start
        end

        derivation
      end

      # @rbs (StateItem state_item, Grammar::Symbol sym) -> Derivation?
      def find_derivation_for_symbol(state_item, sym)
        queue = [] #: Array[Array[StateItem]]
        queue << [state_item]

        while (sis = queue.shift)
          si = sis.last
          next_sym = si.item.next_sym

          if next_sym == sym
            derivation = nil

            sis.reverse_each do |si|
              derivation = Derivation.new(si.item, derivation)
            end

            return derivation
          end

          if next_sym.nterm? && next_sym.first_set.include?(sym)
            @counterexamples.productions[si].each do |next_item|
              next if next_item.empty_rule?
              next_si = StateItem.new(si.state, next_item)
              next if sis.include?(next_si)
              queue << (sis + [next_si])
            end

            if next_sym.nullable
              next_si = @counterexamples.transitions[[si, next_sym]]
              queue << (sis + [next_si])
            end
          end
        end
      end
    end
  end
end
