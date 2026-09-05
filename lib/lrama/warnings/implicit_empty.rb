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
        @logger = logger
        @warnings = warnings
      end

      # @rbs (Lrama::Grammar grammar) -> void
      def warn(grammar)
        return unless @warnings

        grammar.rule_builders.each do |builder|
          if builder.rhs.empty?
            lhs = builder.lhs #: Lrama::Lexer::Token::Base
            @logger.warn(lhs.location.generate_error_message("empty rule for #{lhs.s_value} without %empty").chomp)
          end
        end
      end
    end
  end
end
