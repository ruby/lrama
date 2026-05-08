# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Warnings
    class UselessPrecedence
      # @rbs (Lrama::Logger logger, bool warnings) -> void
      def initialize(logger, warnings)
        @emitter = Lrama::Diagnostic::Emitter.new(logger)
        @warnings = warnings
      end

      # @rbs (Lrama::Grammar grammar, Lrama::States states) -> void
      def warn(grammar, states)
        diagnostics(grammar, states).each do |diagnostic|
          @emitter.warn(diagnostic, message: legacy_message(diagnostic))
        end
      end

      # @rbs (Lrama::Grammar grammar, Lrama::States states) -> Array[Lrama::Diagnostic]
      def diagnostics(grammar, _states)
        return [] unless @warnings

        grammar.precedences.each_with_object([]) do |precedence, diagnostics|
          next if precedence.used_by?

          diagnostics << Lrama::Diagnostic.new(
            id: "useless_precedence",
            severity: :warning,
            message: "Precedence #{precedence.s_value} is defined but not used in any rule.",
            location: Lrama::Diagnostic::Location.new(line: precedence.lineno),
            details: {
              "precedence" => precedence.s_value,
              "line" => precedence.lineno
            },
            suggestion: "Remove the precedence declaration or use it with %prec in a rule."
          )
        end
      end

      private

      # @rbs (Lrama::Diagnostic diagnostic) -> String
      def legacy_message(diagnostic)
        "Precedence #{diagnostic.details["precedence"]} (line: #{diagnostic.details["line"]}) is defined but not used in any rule."
      end
    end
  end
end
