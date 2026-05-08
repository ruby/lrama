# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Diagnostic
    class Location
      attr_reader :filename #: String?
      attr_reader :line #: Integer?
      attr_reader :column #: Integer?
      attr_reader :end_line #: Integer?
      attr_reader :end_column #: Integer?

      # @rbs (?filename: String?, ?line: Integer?, ?column: Integer?, ?end_line: Integer?, ?end_column: Integer?) -> void
      def initialize(filename: nil, line: nil, column: nil, end_line: nil, end_column: nil)
        @filename = filename
        @line = line
        @column = column
        @end_line = end_line
        @end_column = end_column
      end

      # @rbs () -> Hash[String, untyped]
      def to_h
        {
          "filename" => filename,
          "line" => line,
          "column" => column,
          "end_line" => end_line,
          "end_column" => end_column
        }
      end

      # @rbs () -> String
      def to_s
        parts = [] #: Array[String | Integer]
        parts << filename if filename
        parts << line if line
        parts << column if line && column
        parts.join(":")
      end
    end
  end
end
