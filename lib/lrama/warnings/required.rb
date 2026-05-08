# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Warnings
    class Required
      # @rbs (Lrama::Logger logger, bool warnings) -> void
      def initialize(logger, warnings = false, **_)
        @emitter = Lrama::Diagnostic::Emitter.new(logger)
        @warnings = warnings
      end

      # @rbs (Lrama::Grammar grammar) -> void
      def warn(grammar)
        diagnostics(grammar).each do |diagnostic|
          @emitter.warn(diagnostic)
        end
        nil
      end

      # @rbs (Lrama::Grammar grammar) -> Array[Lrama::Diagnostic]
      def diagnostics(grammar)
        return [] unless @warnings
        return [] unless grammar.required

        [
          Lrama::Diagnostic.new(
            id: "require.noop",
            severity: :warning,
            message: "currently, %require is simply valid as a grammar but does nothing",
            suggestion: "Remove %require if it is not needed for Bison compatibility."
          )
        ]
      end
    end
  end
end
