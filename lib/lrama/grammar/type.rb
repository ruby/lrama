# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    class Type
      # TODO: rbs-inline 0.11.0 doesn't support instance variables.
      #       Move these type declarations above instance variable definitions, once it's supported.
      #       see: https://github.com/soutaro/rbs-inline/pull/149
      #
      # @rbs!
      #   @id: Lexer::Token::Base
      #   @tag: Lexer::Token::Tag?
      #   @alias_name: String?

      attr_reader :id #: Lexer::Token::Base
      attr_reader :tag #: Lexer::Token::Tag?
      attr_reader :alias_name #: String?

      # @rbs (id: Lexer::Token::Base, tag: Lexer::Token::Tag?, ?alias_name: String?) -> void
      def initialize(id:, tag:, alias_name: nil)
        @id = id
        @tag = tag
        @alias_name = alias_name
      end

      # @rbs (Grammar::Type other) -> bool
      def ==(other)
        self.class == other.class &&
        self.id == other.id &&
        self.tag == other.tag &&
        self.alias_name == other.alias_name
      end
    end
  end
end
