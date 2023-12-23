module Lrama
  class Lexer
    class Location
      attr_reader :grammar_file_path, :first_line, :first_column, :last_line, :last_column

      def initialize(grammar_file_path:, first_line:, first_column:, last_line:, last_column:)
        @grammar_file_path = grammar_file_path
        @first_line = first_line
        @first_column = first_column
        @last_line = last_line
        @last_column = last_column
      end

      def ==(other)
        self.class == other.class &&
        self.grammar_file_path == other.grammar_file_path &&
        self.first_line == other.first_line &&
        self.first_column == other.first_column &&
        self.last_line == other.last_line &&
        self.last_column == other.last_column
      end

      def to_s
        "#{grammar_file_path} (#{first_line},#{first_column})-(#{last_line},#{last_column})"
      end
    end
  end
end
