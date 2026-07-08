# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    # Represents a lexer context defined by %lexer-context directive.
    #
    # Example:
    #   %lexer-context BEG keyword_if keyword_unless '(' '[' '{'
    #
    # The bitmask value is automatically assigned by definition order (1 << index).
    class LexerContext
      attr_reader :name #: String
      attr_reader :index #: Integer
      attr_reader :symbols #: Array[Lexer::Token::Ident]

      # @rbs (name: String, index: Integer) -> void
      def initialize(name:, index:)
        @name = name
        @index = index
        @symbols = []
      end

      # Bitmask value for this context (1 << index).
      # @rbs () -> Integer
      def bitmask
        1 << @index
      end

      # Add symbols that belong to this context.
      # @rbs (Array[Lexer::Token::Ident] syms) -> void
      def add_symbols(syms)
        syms.each do |sym|
          @symbols << sym
        end
      end
    end
  end
end
