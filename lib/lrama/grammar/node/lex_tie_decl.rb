# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    module Node
      class LexTieDecl < Base
        attr_reader :operands #: Array[Lexer::Token::Base]
        attr_reader :kind #: :tie | :no_tie

        # @rbs (operands: Array[Lexer::Token::Base], kind: :tie | :no_tie, location: Lexer::Location) -> void
        def initialize(operands:, kind:, location:)
          @operands = operands
          @kind = kind
          super(location: location)
        end
      end
    end
  end
end
