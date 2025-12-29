# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    class SemanticPredicate
      # @rbs!
      #   type position = :leading | :trailing | :middle | :unknown

      attr_reader :token #: Lexer::Token::SemanticPredicate
      attr_reader :code #: String
      attr_accessor :position #: position
      attr_accessor :index #: Integer?

      # @rbs (Lexer::Token::SemanticPredicate token) -> void
      def initialize(token)
        @token = token
        @code = token.code
        @position = :unknown
        @index = nil
      end

      # @rbs () -> bool
      def visible?
        @position == :leading
      end

      # @rbs () -> String
      def function_name
        raise "Predicate index not set" if @index.nil?
        "yypredicate_#{@index}"
      end

      # @rbs () -> String
      def error_message
        "semantic predicate failed: {#{code}}?"
      end

      # @rbs () -> Lexer::Location
      def location
        @token.location
      end

      # @rbs () -> String
      def to_s
        "{#{code}}?"
      end
    end
  end
end
