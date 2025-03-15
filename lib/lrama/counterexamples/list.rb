# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Counterexamples
    # singly-linked list
    #
    # @rbs generic E < Object -- Type of an element
    class List
      # @rbs generic E < Object -- Type of an element
      class Node
        attr_reader :elem #: E
        attr_reader :next_node #: Node[E]?

        # @rbs (E elem, Node[E]? next_node) -> void
        def initialize(elem, next_node)
          @elem = elem
          @next_node = next_node
        end
      end

      # @rbs!
      #   @first_node: Node[E]

      # @rbs (E elem) -> void
      def initialize(elem)
        @first_node = Node.new(elem, nil)
      end

      # @rbs () -> E
      def first
        @first_node.elem
      end

      # @rbs (E elem) -> void
      def add_first(elem)
        @first_node = Node.new(elem, @first_node)
      end

      # @rbs () -> Array[E]
      def to_a
        a = [] # steep:ignore UnannotatedEmptyCollection
        node = @first_node

        while (node)
          a << node.elem
          node = node.next_node
        end

        a
      end
    end
  end
end
