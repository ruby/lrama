# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    module Node
      class LexerContextDecl < Base
        attr_reader :name #: String
        attr_reader :symbols #: Array[Lexer::Token::Base]

        # @rbs (name: String, symbols: Array[Lexer::Token::Base], location: Lexer::Location) -> void
        def initialize(name:, symbols:, location:)
          @name = name
          @symbols = symbols
          super(location: location)
        end
      end
    end
  end
end
