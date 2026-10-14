# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Warnings
    class LexicalTieCandidates
      # @rbs (Logger logger, bool warnings) -> void
      def initialize(logger, warnings)
        @logger = logger
        @warnings = warnings
      end

      # @rbs (Lrama::States states) -> void
      def warn(states)
        return unless @warnings
        return unless states.respond_to?(:lexical_tie_candidates)

        states.lexical_tie_candidates.each do |left, right|
          @logger.warn(
            "lexical tie candidate: #{left} and #{right} conflict lexically but are not tied; " \
            "add %lex-tie #{left} #{right} or %lex-no-tie #{left} #{right}"
          )
        end
      end
    end
  end
end
