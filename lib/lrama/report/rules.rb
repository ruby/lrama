# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Report
    class Rules
      # @rbs (rules: bool, **untyped _) -> void
      def initialize(rules: false, **_)
        @rules = rules
      end

      # @rbs (Lrama::States states, Lrama::Logger logger) -> void
      def report(states, logger)
        return unless @rules

        used_rules = states.rules.flat_map(&:rhs)

        unused_rules = states.rules.map(&:lhs).select do |rule|
          !used_rules.include?(rule) && rule.token_id != 0
        end

        unless unused_rules.empty?
          logger.trace("#{unused_rules.count} Unused Rules\n")
          unused_rules.each_with_index do |rule, index|
            logger.trace(sprintf("%5d %s", index, rule.display_name))
          end
          logger.trace("\n")
        end
      end
    end
  end
end
