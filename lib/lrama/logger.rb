# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Logger
    attr_reader :reporter #: Diagnostics::Reporter

    # @rbs (?IO out) -> void
    def initialize(out = $stderr)
      @out = out
      @reporter = Diagnostics::Reporter.new(
        output: out,
        color_mode: Diagnostics::Color.enabled ? :always : :never
      )
    end

    # @rbs () -> void
    def line_break
      @out << "\n"
    end

    # @rbs (String message) -> void
    def trace(message)
      @out << message << "\n"
    end

    # @rbs (String message, ?location: untyped, ?source_line: String?) -> void
    def warn(message, location: nil, source_line: nil)
      if location
        @reporter.warning(
          location: location,
          message: message,
          source_line: source_line
        )
      else
        prefix = Diagnostics::Color.colorize('warning', :warning)
        @out << prefix << ': ' << message << "\n"
      end
    end

    # @rbs (String message, ?location: untyped, ?source_line: String?) -> void
    def error(message, location: nil, source_line: nil)
      if location
        @reporter.error(
          location: location,
          message: message,
          source_line: source_line
        )
      else
        prefix = Diagnostics::Color.colorize('error', :error)
        @out << prefix << ': ' << message << "\n"
      end
    end

    # @rbs () -> Integer
    def error_count
      @reporter.error_count
    end

    # @rbs () -> Integer
    def warning_count
      @reporter.warning_count
    end

    # @rbs () -> bool
    def errors?
      @reporter.errors?
    end

    # @rbs () -> bool
    def warnings?
      @reporter.warnings?
    end

    # @rbs () -> String
    def summary
      @reporter.summary
    end
  end
end
