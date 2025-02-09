# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Report
    class Rules
      # @rbs (Lrama::States states, File io, rules: bool, **untyped _) -> void
      def self.report(states, io, rules: false, **_)
        new(states, io).report if rules
      end

      # @rbs (Lrama::States states, File io) -> void
      def initialize(states, io)
        @states = states
        @io = io
      end

      # @rbs () -> void
      def report
        used_rules = @states.rules.flat_map(&:rhs)

        unused_rules = @states.rules.map(&:lhs).select do |rule|
          !used_rules.include?(rule) && rule.token_id != 0
        end

        unless unused_rules.empty?
          @io << "#{unused_rules.count} Unused Rules\n\n"
          unused_rules.each_with_index do |rule, index|
            @io << sprintf("%5d %s\n", index, rule.display_name)
          end
          @io << "\n\n"
        end
      end
    end
  end
end
