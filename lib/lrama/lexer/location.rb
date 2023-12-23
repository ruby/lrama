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

      def partial_location(left, right)
        offset = -first_column
        new_first_line = -1
        new_first_column = -1
        new_last_line = -1
        new_last_column = -1

        _text.each.with_index do |line, index|
          new_offset = offset + line.length + 1

          if offset <= left && left <= new_offset
            new_first_line = first_line + index
            new_first_column = left - offset
          end

          if offset <= right && right <= new_offset
            new_last_line = first_line + index
            new_last_column = right - offset
          end

          offset = new_offset
        end

        Location.new(
          grammar_file_path: grammar_file_path,
          first_line: new_first_line, first_column: new_first_column,
          last_line: new_last_line, last_column: new_last_column
        )
      end

      def to_s
        "#{grammar_file_path} (#{first_line},#{first_column})-(#{last_line},#{last_column})"
      end

      def generate_error_message(error_message)
        <<~ERROR.chomp
          #{grammar_file_path}:#{first_line}:#{first_column}: #{error_message}
          #{line_with_carrets}
        ERROR
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
        _text.join("\n")
      end

      def _text
        return @_text if @_text

        @_text = File.read(grammar_file_path).split("\n")[(first_line - 1)...last_line]
        @_text
      end
    end
  end
end
