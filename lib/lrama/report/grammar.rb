# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Report
    class Grammar
      # @rbs (Lrama::States states, File io, grammar: bool, **untyped _) -> void
      def self.report(states, io, grammar: false, **_)
        new(states, io).report if grammar
      end

      # @rbs (Lrama::States states, File io) -> void
      def initialize(states, io)
        @states = states
        @io = io
      end

      # @rbs () -> void
      def report
        @io << "Grammar\n"
        last_lhs = nil

        @states.rules.each do |rule|
          if rule.empty_rule?
            r = "ε"
          else
            r = rule.rhs.map(&:display_name).join(" ")
          end

          if rule.lhs == last_lhs
            @io << sprintf("%5d %s| %s\n", rule.id, " " * rule.lhs.display_name.length, r)
          else
            @io << "\n"
            @io << sprintf("%5d %s: %s\n", rule.id, rule.lhs.display_name, r)
          end

          last_lhs = rule.lhs
        end
        @io << "\n\n"
      end
    end
  end
end
