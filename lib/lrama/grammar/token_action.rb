# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    # Represents a token action defined by %token-action directive.
    #
    # Token actions are user code blocks associated with token patterns.
    # When a token is matched by the pseudo-scanner, the associated code runs.
    # Layout tokens are accumulated, and the accumulated text is available
    # to the next non-layout token's action.
    #
    # Example:
    #   %token-action ID { printf("matched ID: %.*s\n", yyleng, yytext); }
    class TokenAction
      attr_reader :token_id #: Lexer::Token::Ident
      attr_reader :code #: Lexer::Token::UserCode
      attr_reader :lineno #: Integer

      # @rbs (token_id: Lexer::Token::Ident, code: Lexer::Token::UserCode, lineno: Integer) -> void
      def initialize(token_id:, code:, lineno:)
        @token_id = token_id
        @code = code
        @lineno = lineno
      end

      # @rbs () -> String
      def token_name
        @token_id.s_value
      end
    end
  end
end
