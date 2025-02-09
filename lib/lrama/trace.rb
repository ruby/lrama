# rbs_inline: enabled
# frozen_string_literal: true

require_relative "trace/actions"
require_relative "trace/duration"
require_relative "trace/only_explicit_rules"
require_relative "trace/rules"


module Lrama
  class Trace
    # @rbs (Lrama::Grammar grammar, **untyped _) -> void
    def self.report(grammar, **options)
      new.report(grammar, **options)
    end

    # @rbs (**Hash[Symbol, bool] options) -> void
    def report(grammar, **options)
      OnlyExplicitRules.report(grammar, **options)
      Rules.report(grammar, **options)
      Actions.report(grammar, **options)
    end
  end
end
