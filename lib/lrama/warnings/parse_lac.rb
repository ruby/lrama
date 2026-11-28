# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Warnings
    class ParseLac
      # @rbs (Logger logger, bool warnings) -> void
      def initialize(logger, warnings)
        @logger = logger
        @warnings = warnings
      end

      # @rbs (Lrama::Grammar grammar) -> void
      def warn(grammar)
        return unless @warnings
        return unless grammar.pslr_defined?
        return unless grammar.parse_lac_explicit_none?

        @logger.warn(
          "parse.lac is disabled for a PSLR parser; " \
          "tokens selected in merged states may trigger semantic actions before a syntax error is detected"
        )
      end
    end
  end
end
