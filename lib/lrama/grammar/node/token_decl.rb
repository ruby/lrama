# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    module Node
      class TokenDecl < Base
        attr_reader :tokens #: Array[Node::Token]

        # @rbs (tokens: Array[Node::Token], location: Lexer::Location) -> void
        def initialize(tokens:, location:)
          @tokens = tokens
          super(location: location)
        end
      end
    end
  end
end
