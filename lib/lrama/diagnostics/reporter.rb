# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  module Diagnostics
    class Reporter
      attr_reader :error_count #: Integer
      attr_reader :warning_count #: Integer
      attr_reader :messages #: Array[Message]
      attr_reader :output #: IO

      # @rbs (?output: IO, ?color_mode: Symbol, ?show_source: bool) -> void
      def initialize(output: $stderr, color_mode: :auto, show_source: true)
        @output = output
        @color_mode = color_mode
        @show_source = show_source

        @error_count = 0
        @warning_count = 0
        @messages = [] #: Array[Message]

        color_enabled = Color.should_colorize?(color_mode, output)
        @formatter = Formatter.new(
          color_enabled: color_enabled,
          show_source: show_source
        )
      end

      # @rbs (location: untyped, message: String, ?source_line: String?, ?notes: Array[Message], ?fixit: String?) -> Message
      def error(location:, message:, source_line: nil, notes: [], fixit: nil)
        msg = Message.new(
          type: :error,
          location: location,
          message: message,
          source_line: source_line,
          notes: notes,
          fixit: fixit
        )
        report(msg)
        msg
      end

      # @rbs (location: untyped, message: String, ?source_line: String?, ?notes: Array[Message], ?fixit: String?) -> Message
      def warning(location:, message:, source_line: nil, notes: [], fixit: nil)
        msg = Message.new(
          type: :warning,
          location: location,
          message: message,
          source_line: source_line,
          notes: notes,
          fixit: fixit
        )
        report(msg)
        msg
      end

      # @rbs (location: untyped, message: String) -> Message
      def note(location:, message:)
        Message.new(
          type: :note,
          location: location,
          message: message
        )
      end

      # @rbs (Message message) -> void
      def report(message)
        @messages << message

        case message.type
        when :error
          @error_count += 1
        when :warning
          @warning_count += 1
        end

        @output.puts @formatter.format(message)
      end

      # @rbs () -> bool
      def errors?
        @error_count > 0
      end

      # @rbs () -> bool
      def warnings?
        @warning_count > 0
      end

      # @rbs () -> bool
      def any?
        !@messages.empty?
      end

      # @rbs () -> String
      def summary
        parts = [] #: Array[String]

        if @error_count > 0
          parts << "#{@error_count} error#{@error_count == 1 ? '' : 's'}"
        end

        if @warning_count > 0
          parts << "#{@warning_count} warning#{@warning_count == 1 ? '' : 's'}"
        end

        parts.empty? ? 'no issues' : parts.join(', ')
      end

      # @rbs () -> void
      def print_summary
        @output.puts summary if any?
      end

      # @rbs () -> void
      def reset
        @error_count = 0
        @warning_count = 0
        @messages.clear
      end

      # @rbs (untyped location) -> String?
      def read_source_line(location)
        return nil unless location&.path

        begin
          File.readlines(location.path)[location.first_line - 1]&.chomp
        rescue StandardError
          nil
        end
      end

      # @rbs (location: untyped, message: String, ?notes: Array[Message]) -> Message
      def error_with_source(location:, message:, notes: [])
        source_line = read_source_line(location)
        error(
          location: location,
          message: message,
          source_line: source_line,
          notes: notes
        )
      end

      # @rbs (location: untyped, message: String, ?notes: Array[Message]) -> Message
      def warning_with_source(location:, message:, notes: [])
        source_line = read_source_line(location)
        warning(
          location: location,
          message: message,
          source_line: source_line,
          notes: notes
        )
      end

      # @rbs () -> Array[Message]
      def sorted_messages
        @messages.sort
      end
    end
  end
end
