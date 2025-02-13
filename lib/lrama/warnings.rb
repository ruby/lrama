# rbs_inline: enabled
# frozen_string_literal: true

require_relative 'warnings/conflicts'
require_relative 'warnings/redefined_rules'

module Lrama
  class Warnings
    # @rbs (Logger logger, bool warnings) -> void
    def initialize(logger, warnings)
      @conflicts = Conflicts.new(logger, warnings)
      @redefined_rules = RedefinedRules.new(logger, warnings)
    end

    # @rbs (Lrama::Grammar grammar, Lrama::States states) -> void
    def warn(grammar, states)
      @conflicts.warn(states)
      @redefined_rules.warn(grammar)
    end
  end
end
