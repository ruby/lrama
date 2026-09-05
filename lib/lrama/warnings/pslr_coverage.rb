# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Warnings
    class PslrCoverage
      # @rbs (Logger logger, bool warnings) -> void
      def initialize(logger, warnings)
        @logger = logger
        @warnings = warnings
      end

      # Bridge mode allows partial coverage: terminals without a
      # %token-pattern must keep coming from the user lexer. List them so
      # the boundary between generated and hand-written scanning is
      # explicit.
      # @rbs (Lrama::Grammar grammar) -> void
      def warn(grammar)
        return unless @warnings
        return unless grammar.pslr_defined?
        return if grammar.pslr_lexer_generated?
        return if grammar.token_patterns.empty?

        uncovered = grammar.uncovered_pslr_terminals
        return if uncovered.empty?

        @logger.warn(
          "PSLR pseudo-scanner does not cover these terminals; " \
          "the user lexer must produce them: #{uncovered.join(', ')}"
        )
      end
    end
  end
end
