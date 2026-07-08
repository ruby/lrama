# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    module Node
      class TokenPatternDecl < Base
        attr_reader :id #: Lexer::Token::Ident
        attr_reader :pattern #: Lexer::Token::Regex
        attr_reader :alias_name #: String?
        attr_accessor :tag #: Lexer::Token::Tag?

        # @rbs (id: Lexer::Token::Ident, pattern: Lexer::Token::Regex, alias_name: String?, location: Lexer::Location) -> void
        def initialize(id:, pattern:, alias_name:, location:)
          @id = id
          @pattern = pattern
          @alias_name = alias_name
          @tag = nil
          super(location: location)
        end
      end
    end
  end
end
