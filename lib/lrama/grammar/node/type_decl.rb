# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    module Node
      class TypeDecl < Base
        attr_reader :symbols #: Array[Node::Symbol]

        # @rbs (symbols: Array[Node::Symbol], location: Lexer::Location) -> void
        def initialize(symbols:, location:)
          @symbols = symbols
          super(location: location)
        end
      end
    end
  end
end
