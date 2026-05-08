# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Warnings
    class RedefinedRules
      # @rbs (Lrama::Logger logger, bool warnings) -> void
      def initialize(logger, warnings)
        @emitter = Lrama::Diagnostic::Emitter.new(logger)
        @warnings = warnings
      end

      # @rbs (Lrama::Grammar grammar) -> void
      def warn(grammar)
        diagnostics(grammar).each do |diagnostic|
          @emitter.warn(diagnostic)
        end
      end

      # @rbs (Lrama::Grammar grammar) -> Array[Lrama::Diagnostic]
      def diagnostics(grammar)
        return [] unless @warnings

        grammar.parameterized_resolver.redefined_rules.map do |rule|
          Lrama::Diagnostic.new(
            id: "parameterized_rule.redefined",
            severity: :warning,
            message: "parameterized rule redefined: #{rule}",
            details: { "rule" => rule.to_s }
          )
        end
      end
    end
  end
end
