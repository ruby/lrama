# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Counterexamples
    class Example
      # TODO: rbs-inline 0.11.0 doesn't support instance variables.
      #       Move these type declarations above instance variable definitions, once it's supported.
      #       see: https://github.com/soutaro/rbs-inline/pull/149
      #
      # @rbs!
      #   @path1: ::Array[StateItem]
      #   @path2: ::Array[StateItem]
      #   @conflict: State::conflict
      #   @conflict_symbols: ::Array[Grammar::Symbol]
      #   @conflict_symbol: Grammar::Symbol
      #   @counterexamples: Counterexamples
      #   @derivations1: Derivation
      #   @derivations2: Derivation

      attr_reader :path1 #: ::Array[StateItem]
      attr_reader :path2 #: ::Array[StateItem]
      attr_reader :conflict #: State::conflict
      attr_reader :conflict_symbols #: ::Array[Grammar::Symbol]
      attr_reader :conflict_symbol #: Grammar::Symbol

      # path1 is shift conflict when S/R conflict
      # path2 is always reduce conflict
      #
      # @rbs (Array[StateItem]? path1, Array[StateItem]? path2, State::conflict conflict, Grammar::Symbol conflict_symbol, Counterexamples counterexamples, ?conflict_symbols: Array[Grammar::Symbol]) -> void
      def initialize(path1, path2, conflict, conflict_symbol, counterexamples, conflict_symbols: [conflict_symbol])
        @path1 = path1
        @path2 = path2
        @conflict = conflict
        @conflict_symbols = conflict_symbols
        @conflict_symbol = conflict_symbol
        @counterexamples = counterexamples
      end

      # @rbs () -> (:shift_reduce | :reduce_reduce)
      def type
        @conflict.type
      end

      # @rbs () -> State::Item
      def path1_item
        @path1.last.item
      end

      # @rbs () -> State::Item
      def path2_item
        @path2.last.item
      end

      # @rbs () -> Derivation
      def derivations1
        @derivations1 ||= _derivations(path1)
      end

      # @rbs () -> Derivation
      def derivations2
        @derivations2 ||= _derivations(path2)
      end

      # @rbs () -> String
      def example1
        (shared_example_symbols || full_example_symbols1).join(" ")
      end

      # @rbs () -> String
      def example2
        (shared_example_symbols || full_example_symbols2).join(" ")
      end

      # @rbs () -> bool
      def same_example?
        example1 == example2
      end

      # @rbs () -> String
      def example1_label
        same_example? ? "Example" : "First example"
      end

      # @rbs () -> String
      def example2_label
        same_example? ? "Example" : "Second example"
      end

      # @rbs () -> String
      def derivation_label1
        type == :shift_reduce ? "Shift derivation" : "First Reduce derivation"
      end

      # @rbs () -> String
      def derivation_label2
        type == :shift_reduce ? "Reduce derivation" : "Second Reduce derivation"
      end

      # @rbs () -> String
      def conflict_label
        labels = conflict_symbols.map { |symbol| normalize_symbol_for_example(symbol.display_name) }
        prefix = labels.size == 1 ? "token" : "tokens"

        "#{prefix} #{labels.join(", ")}"
      end

      # @rbs (Array[Grammar::Symbol]) -> Example
      def merge_conflict_symbols!(symbols)
        @conflict_symbols |= symbols
        self
      end

      # @rbs () -> Array[untyped]
      def merge_key
        [
          type,
          path1.map(&:id),
          path2.map(&:id),
          example1_label,
          example1,
          derivations1.render_for_report,
          example2_label,
          example2,
          derivations2.render_for_report
        ]
      end

      private

      # @rbs (Array[StateItem] state_items) -> Derivation
      def _derivations(state_items)
        derivation = nil #: Derivation
        current = :production
        last_state_item = state_items.last #: StateItem
        lookahead_sym = last_state_item.item.end_of_rule? ? @conflict_symbol : nil

        state_items.reverse_each do |si|
          item = si.item

          case current
          when :production
            case si.type
            when :start
              derivation = Derivation.new(item, derivation)
              current = :start
            when :transition
              derivation = Derivation.new(item, derivation)
              current = :transition
            when :production
              derivation = Derivation.new(item, derivation)
              current = :production
            else
              raise "Unexpected. #{si}"
            end

            if lookahead_sym && item.next_next_sym && item.next_next_sym.first_set.include?(lookahead_sym)
              si2 = @counterexamples.transitions[[si, item.next_sym]]
              derivation2 = find_derivation_for_symbol(si2, lookahead_sym)
              derivation.right = derivation2 # steep:ignore
              lookahead_sym = nil
            end

          when :transition
            case si.type
            when :start
              derivation = Derivation.new(item, derivation)
              current = :start
            when :transition
              # ignore
              current = :transition
            when :production
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
            @counterexamples.productions[si].each do |next_si|
              next if next_si.item.empty_rule?
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

      # @rbs (String name) -> String
      def normalize_symbol_for_example(name)
        name == '"end of file"' ? "$end" : name
      end

      # @rbs () -> Array[String]
      def full_example_symbols1
        derivations1.render_symbols_for_example
      end

      # @rbs () -> Array[String]
      def full_example_symbols2
        derivations2.render_symbols_for_example
      end

      # @rbs () -> Array[String]?
      def shared_example_symbols
        return @shared_example_symbols if instance_variable_defined?(:@shared_example_symbols)

        @shared_example_symbols = build_shared_example_symbols
      end

      # @rbs () -> Array[String]?
      def build_shared_example_symbols
        return full_example_symbols1 if full_example_symbols1 == full_example_symbols2
        return nil unless type == :shift_reduce

        common = common_prefix(full_example_symbols1, full_example_symbols2)
        dot_index = common.index("•")
        return nil unless dot_index

        shared_after_dot_length = common.length - dot_index - 1
        return nil if shared_after_dot_length < path1_item.symbols_after_dot.length

        common
      end

      # @rbs (Array[String] a, Array[String] b) -> Array[String]
      def common_prefix(a, b)
        prefix = [] #: Array[String]

        a.zip(b) do |left, right|
          break unless left && right
          break unless left == right

          prefix << left
        end

        prefix
      end
    end
  end
end
