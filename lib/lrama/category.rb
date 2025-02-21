# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Category
    attr_reader :id #: Lrama::Lexer::Token::Ident
    attr_reader :name #: String
    attr_reader :tokens #: Array[Lrama::Lexer::Token::Ident]
    attr_reader :tag #: Lexer::Token::Tag

    # @rbs (id: Lrama::Lexer::Token::Ident) -> void
    def initialize(id:)
      @id = id
      @name = id.s_value
      @tokens = []
      @tag = nil
    end

    # @rbs (Array[Lrama::Lexer::Token::Ident] tokens, Lexer::Token::Tag tag) -> void
    def add_tokens(tokens, tag)
      @tag = tag
      tokens.each do |token|
        @tokens << Lrama::Lexer::Token::Ident.new(s_value: token.s_value, location: token.location)
      end
    end
  end
end
