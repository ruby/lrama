# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    # Represents a token pattern defined by %token-pattern directive
    # Example: %token-pattern RSHIFT />>/ "right shift"
    class TokenPattern
      attr_reader :id #: Lexer::Token::Ident
      attr_reader :pattern #: Lexer::Token::Regex
      attr_reader :alias_name #: String?
      attr_reader :tag #: Lexer::Token::Tag?
      attr_reader :lineno #: Integer
      attr_reader :definition_order #: Integer

      # @rbs (id: Lexer::Token::Ident, pattern: Lexer::Token::Regex, ?alias_name: String?, ?tag: Lexer::Token::Tag?, lineno: Integer, definition_order: Integer) -> void
      def initialize(id:, pattern:, alias_name: nil, tag: nil, lineno:, definition_order:)
        @id = id
        @pattern = pattern
        @alias_name = alias_name
        @tag = tag
        @lineno = lineno
        @definition_order = definition_order
      end

      # @rbs () -> String
      def name
        @id.s_value
      end

      # Returns the regex pattern string (without slashes)
      # @rbs () -> String
      def regex_pattern
        @pattern.pattern
      end
    end
  end
end
