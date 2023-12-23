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

      def line_with_carrets
        <<~TEXT
          #{text}
          #{carrets}
        TEXT
      end

      private

      def blanks
        (text[0...first_column] or raise "#{first_column} is invalid").gsub(/[^\t]/, ' ')
      end

      def carrets
        blanks + '^' * (last_column - first_column)
      end

      def text
        return @text if @text

        @text = File.read(grammar_file_path).split("\n")[first_line - 1]
        @text
      end
    end
  end
end
