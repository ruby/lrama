# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    module Node
      class PrinterDecl < Base
        attr_reader :ident_or_tags #: Array[Lexer::Token::Ident | Lexer::Token::Tag]
        attr_reader :code #: Lexer::Token::UserCode

        # @rbs (ident_or_tags: Array[Lexer::Token::Ident | Lexer::Token::Tag], code: Lexer::Token::UserCode, location: Lexer::Location) -> void
        def initialize(ident_or_tags:, code:, location:)
          @ident_or_tags = ident_or_tags
          @code = code
          super(location: location)
        end
      end
    end
  end
end
