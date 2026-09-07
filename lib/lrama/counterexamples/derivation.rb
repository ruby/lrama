# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Counterexamples
    class Derivation
      # @rbs!
      #   @item: State::Item
      #   @left: Derivation?

      attr_reader :item  #: State::Item
      attr_reader :left  #: Derivation?
      attr_accessor :right #: Derivation?

      # @rbs (State::Item item, Derivation? left) -> void
      def initialize(item, left)
        @item = item
        @left = left
      end

      # @rbs () -> ::String
      def to_s
        "#<Derivation(#{item.display_name})>"
      end
      alias :inspect :to_s

      # @rbs () -> Array[String]
      def render_strings_for_report
        result = [] #: Array[String]
        _render_for_report(self, 0, result, 0)
        result.map(&:rstrip)
      end

      # @rbs () -> String
      def render_for_report
        render_strings_for_report.join("\n")
      end

      # @rbs (?Derivation derivation) -> Array[String]
      def render_symbols_for_example(derivation = self)
        _render_symbols_for_example(derivation)
      end

      private

      # @rbs (Derivation derivation, Integer offset, Array[String] strings, Integer index) -> Integer
      def _render_for_report(derivation, offset, strings, index)
        item = derivation.item
        if strings[index]
          strings[index] << " " * (offset - strings[index].length)
        else
          strings[index] = " " * offset
        end
        str = strings[index]
        str << "#{item.rule_id}: #{item.symbols_before_dot.map(&:display_name).join(" ")} "

        if derivation.left
          len = str.length
          str << "#{item.next_sym.display_name}"
          length = _render_for_report(derivation.left, len, strings, index + 1)
          # I want String#ljust!
          str << " " * (length - str.length) if length > str.length
        else
          str << " • #{item.symbols_after_dot.map(&:display_name).join(" ")} "
          return str.length
        end

        if derivation.right&.left
          left = derivation.right&.left #: Derivation
          length = _render_for_report(left, str.length, strings, index + 1)
          str << "#{item.symbols_after_dot[1..-1].map(&:display_name).join(" ")} " # steep:ignore
          str << " " * (length - str.length) if length > str.length
        elsif item.next_next_sym
          str << "#{item.symbols_after_dot[1..-1].map(&:display_name).join(" ")} " # steep:ignore
        end

        return str.length
      end

      # @rbs (Derivation derivation) -> Array[String]
      def _render_symbols_for_example(derivation)
        item = derivation.item
        result = item.symbols_before_dot.map do |symbol|
          normalize_symbol_for_example(symbol.display_name)
        end

        if derivation.left
          result.concat(_render_symbols_for_example(derivation.left))
        else
          result << "•"
          result.concat(item.symbols_after_dot.map { |symbol| normalize_symbol_for_example(symbol.display_name) })
          return result
        end

        if (right = derivation.right&.left)
          result.concat(_render_symbols_for_example(right))
          tail = item.symbols_after_dot.drop(2)
        else
          tail = item.symbols_after_dot.drop(1)
        end

        result.concat(tail.map { |symbol| normalize_symbol_for_example(symbol.display_name) })
      end

      # @rbs (String name) -> String
      def normalize_symbol_for_example(name)
        name == '"end of file"' ? "$end" : name
      end
    end
  end
end
