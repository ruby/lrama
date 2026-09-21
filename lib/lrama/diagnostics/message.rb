# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  module Diagnostics
    class Message
      SEVERITY = {
        error:   3,
        warning: 2,
        note:    1
      }.freeze

      attr_reader :type #: Symbol
      attr_reader :location #: untyped
      attr_reader :message #: String
      attr_reader :source_line #: String?
      attr_reader :notes #: Array[Message]
      attr_reader :fixit #: String?

      # @rbs (type: Symbol, location: untyped, message: String, ?source_line: String?, ?notes: Array[Message], ?fixit: String?) -> void
      def initialize(type:, location:, message:, source_line: nil, notes: [], fixit: nil)
        @type = type
        @location = location
        @message = message
        @source_line = source_line
        @notes = notes
        @fixit = fixit
      end

      # @rbs () -> Integer
      def severity
        SEVERITY[@type] || 0
      end

      # @rbs () -> bool
      def error?
        @type == :error
      end

      # @rbs () -> bool
      def warning?
        @type == :warning
      end

      # @rbs () -> bool
      def note?
        @type == :note
      end

      # @rbs () -> String?
      def file
        location&.path || location&.filename
      end

      # @rbs () -> Integer?
      def line
        location&.first_line
      end

      # @rbs () -> Integer?
      def column
        location&.first_column
      end

      # @rbs () -> Integer?
      def end_line
        location&.last_line
      end

      # @rbs () -> Integer?
      def end_column
        location&.last_column
      end

      # @rbs () -> bool
      def location?
        !location.nil?
      end

      # @rbs () -> bool
      def source_line?
        !source_line.nil? && !source_line.empty?
      end

      # @rbs () -> bool
      def notes?
        !notes.empty?
      end

      # @rbs () -> bool
      def fixit?
        !fixit.nil? && !fixit.empty?
      end

      # @rbs () -> Integer
      def range_length
        return 1 unless location? && line == end_line

        col = column || 0
        end_col = end_column || col
        [(end_col - col), 1].max
      end

      # @rbs (untyped other) -> Integer?
      def <=>(other)
        return nil unless other.is_a?(Message)

        result = other.severity <=> severity
        return result unless result.zero?

        result = (file || '') <=> (other.file || '')
        return result unless result.zero?

        (line || 0) <=> (other.line || 0)
      end

      # @rbs () -> String
      def inspect
        "#<#{self.class} type=#{type} location=#{location&.to_s || 'nil'} message=#{message.inspect}>"
      end

      # @rbs () -> String
      def to_s
        if location?
          "#{file}:#{line}:#{column}: #{type}: #{message}"
        else
          "#{type}: #{message}"
        end
      end

      # @rbs (Message note) -> self
      def add_note(note)
        @notes << note
        self
      end

      # @rbs () -> Message
      def dup
        Message.new(
          type: @type,
          location: @location,
          message: @message,
          source_line: @source_line,
          notes: @notes.dup,
          fixit: @fixit
        )
      end
    end
  end
end
