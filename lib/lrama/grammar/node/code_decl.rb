# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    module Node
      class CodeDecl < Base
        attr_reader :id #: Lexer::Token::Ident
        attr_reader :code #: Lexer::Token::UserCode

        # @rbs (id: Lexer::Token::Ident, code: Lexer::Token::UserCode, location: Lexer::Location) -> void
        def initialize(id:, code:, location:)
          @id = id
          @code = code
          super(location: location)
        end
      end
    end
  end
end
