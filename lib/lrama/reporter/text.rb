# rbs_inline: enabled
# frozen_string_literal: true

require_relative "../diagnostic"

module Lrama
  class Reporter
    class Text
      # @rbs (Array[Lrama::Diagnostic] diagnostics) -> String
      def report(diagnostics)
        diagnostics.map { |diagnostic| format_diagnostic(diagnostic) }.join("\n")
      end

      private

      # @rbs (Lrama::Diagnostic diagnostic) -> String
      def format_diagnostic(diagnostic)
        lines = ["#{location_prefix(diagnostic.location)}#{diagnostic.severity}[#{diagnostic.id}]: #{diagnostic.message}"]
        lines << "  suggestion: #{diagnostic.suggestion}" if diagnostic.suggestion && !diagnostic.suggestion.empty?
        lines.join("\n")
      end

      # @rbs (Lrama::Diagnostic::Location? location) -> String
      def location_prefix(location)
        return "" unless location

        formatted_location = location.to_s
        return "" if formatted_location.empty?

        "#{formatted_location}: "
      end
    end
  end
end
