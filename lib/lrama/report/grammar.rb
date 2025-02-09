# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Report
    class Grammar
      # @rbs (grammar: bool, **untyped _) -> void
      def initialize(grammar: false, **_)
        @grammar = grammar
      end

      # @rbs (Lrama::States states, Lrama::Logger logger) -> void
      def report(states, logger)
        return unless @grammar

        logger.trace("Grammar")
        last_lhs = nil

        states.rules.each do |rule|
          if rule.empty_rule?
            r = "ε"
          else
            r = rule.rhs.map(&:display_name).join(" ")
          end

          if rule.lhs == last_lhs
            logger.trace(sprintf("%5d %s| %s", rule.id, " " * rule.lhs.display_name.length, r))
          else
            logger.line_break
            logger.trace(sprintf("%5d %s: %s", rule.id, rule.lhs.display_name, r))
          end

          last_lhs = rule.lhs
        end
        logger.trace("\n")
      end
    end
  end
end
