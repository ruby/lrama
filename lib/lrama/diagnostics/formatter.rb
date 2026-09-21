# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  module Diagnostics
    class Formatter
      GUTTER_WIDTH = 5
      GUTTER_SEPARATOR = ' | '

      # @rbs (?color_enabled: bool, ?show_source: bool, ?show_caret: bool) -> void
      def initialize(color_enabled: false, show_source: true, show_caret: true)
        @color_enabled = color_enabled
        @show_source = show_source
        @show_caret = show_caret
      end

      # @rbs (Message message) -> String
      def format(message)
        lines = [] #: Array[String]

        lines << format_main_line(message)

        if @show_source && message.source_line?
          lines << format_source_line(message)

          if @show_caret
            lines << format_caret_line(message)
          end

          if message.fixit?
            lines << format_fixit_line(message)
          end
        end

        message.notes.each do |note|
          lines << format_note(note)
        end

        lines.join("\n")
      end

      # @rbs (Array[Message] messages) -> String
      def format_all(messages)
        messages.map { |m| format(m) }.join("\n\n")
      end

      private

      # @rbs (Message message) -> String
      def format_main_line(message)
        parts = [] #: Array[String]

        if message.location?
          parts << format_location(message)
          parts << ': '
        end

        parts << colorize(message.type.to_s, message.type)
        parts << ': '
        parts << format_message_text(message.message)

        parts.join
      end

      # @rbs (Message message) -> String
      def format_location(message)
        return '' unless message.location?

        str = "#{message.file}:#{message.line}"

        if message.line == message.end_line
          if message.column == message.end_column
            str += ".#{message.column}"
          else
            str += ".#{message.column}-#{message.end_column}"
          end
        else
          str += ".#{message.column}-#{message.end_line}.#{message.end_column}"
        end

        colorize(str, :location)
      end

      # @rbs (String text) -> String
      def format_message_text(text)
        text.gsub(/'([^']+)'/) do |_match|
          quoted = $1 || ''
          "'" + colorize(quoted, :quote) + "'"
        end
      end

      # @rbs (Message message) -> String
      def format_source_line(message)
        line_num = message.line.to_s.rjust(GUTTER_WIDTH)
        gutter = "#{line_num}#{GUTTER_SEPARATOR}"
        source = highlight_source(message)

        "#{gutter}#{source}"
      end

      # @rbs (Message message) -> String
      def highlight_source(message)
        source = message.source_line || ''
        return source unless @color_enabled && message.location?

        col = (message.column || 1) - 1
        end_col = (message.end_column || message.column || 1) - 1

        return source if col < 0 || col >= source.length
        end_col = [end_col, source.length].min

        before = source[0...col] || ''
        highlight = source[col...end_col] || ''
        after = source[end_col..-1] || ''

        "#{before}#{colorize(highlight, :unexpected)}#{after}"
      end

      # @rbs (Message message) -> String
      def format_caret_line(message)
        gutter = ' ' * GUTTER_WIDTH + GUTTER_SEPARATOR
        padding = leading_whitespace(message)
        caret = build_caret(message)

        "#{gutter}#{padding}#{colorize(caret, :caret)}"
      end

      # @rbs (Message message) -> String
      def leading_whitespace(message)
        source = message.source_line || ''
        col = message.column || 0
        return '' if col <= 0

        prefix = source[0...col] || ''
        prefix.gsub(/[^\t]/, ' ')
      end

      # @rbs (Message message) -> String
      def build_caret(message)
        length = message.range_length

        if length <= 1
          '^'
        else
          '^' + '~' * (length - 1)
        end
      end

      # @rbs (Message message) -> String
      def format_fixit_line(message)
        gutter = ' ' * GUTTER_WIDTH + GUTTER_SEPARATOR
        padding = ' ' * [(message.column || 1) - 1, 0].max
        fixit_text = colorize(message.fixit || '', :fixit_insert)

        "#{gutter}#{padding}#{fixit_text}"
      end

      # @rbs (Message note) -> String
      def format_note(note)
        parts = [] #: Array[String]

        if note.location?
          parts << format_location(note)
          parts << ': '
        end

        parts << colorize('note', :note)
        parts << ': '
        parts << note.message

        parts.join
      end

      # @rbs (String? text, Symbol style) -> String
      def colorize(text, style)
        return text || '' unless @color_enabled

        Color.colorize(text || '', style)
      end
    end
  end
end
