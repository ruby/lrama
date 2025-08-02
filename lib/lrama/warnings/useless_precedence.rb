# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Warnings
    class UselessPrecedence
      # @rbs (Lrama::Logger logger, bool warnings) -> void
      def initialize(logger, warnings)
        @logger = logger
        @warnings = warnings
      end

      # @rbs (Lrama::Grammar grammar, Lrama::States states) -> void
      def warn(grammar, states)
        return unless @warnings

        used_rules = states.rules.flat_map do |state|
          state.rhs.flat_map { |sym| sym.id.s_value }
        end.uniq

        grammar.precedences.each do |precedence|
          unless used_rules.include?(precedence.s_value)
            @logger.warn("Precedence #{precedence.s_value} (line: #{precedence.lineno}) is defined but not used in any rule.")
          end
        end
      end
    end
  end
end
