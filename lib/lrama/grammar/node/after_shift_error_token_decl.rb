# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    module Node
      class AfterShiftErrorTokenDecl < Base
        attr_reader :id #: Lexer::Token::Ident

        # @rbs (id: Lexer::Token::Ident, location: Lexer::Location) -> void
        def initialize(id:, location:)
          @id = id
          super(location: location)
        end
      end
    end
  end
end
