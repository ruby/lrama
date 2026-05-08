# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Warnings
    # Warning rationale: Empty rules are easily overlooked and ambiguous
    # - Empty alternatives like `rule: | "token";` can be missed during code reading
    # - Difficult to distinguish between intentional empty rules vs. omissions
    # - Explicit marking with %empty directive comment improves clarity
    class ImplicitEmpty
      # @rbs (Lrama::Logger logger, bool warnings) -> void
      def initialize(logger, warnings)
        @emitter = Lrama::Diagnostic::Emitter.new(logger)
        @warnings = warnings
      end

      # @rbs (Lrama::Grammar grammar) -> void
      def warn(grammar)
        diagnostics(grammar).each do |diagnostic|
          @emitter.warn(diagnostic, message: "warning: #{diagnostic.message}")
        end
        nil
      end

      # @rbs (Lrama::Grammar grammar) -> Array[Lrama::Diagnostic]
      def diagnostics(grammar)
        return [] unless @warnings

        grammar.rule_builders.each_with_object([]) do |builder, diagnostics|
          if builder.rhs.empty?
            diagnostics << Lrama::Diagnostic.new(
              id: "implicit_empty_rule",
              severity: :warning,
              message: "empty rule without %empty",
              location: location_for_line(builder.line),
              details: { "line" => builder.line },
              suggestion: "Use %empty to mark the empty rule explicitly."
            )
          end
        end
      end

      private

      # @rbs (Integer? line) -> Lrama::Diagnostic::Location?
      def location_for_line(line)
        return nil unless line

        Lrama::Diagnostic::Location.new(line: line)
      end
    end
  end
end
