# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Tracer
    # @rbs (Lrama::Grammar grammar, **untyped _) -> void
    def self.call(grammar, **options)
      new.call(grammar, **options)
    end

    # @rbs (**Hash[Symbol, bool] options) -> void
    def call(grammar, **options)
      Lrama::Trace::OnlyExplicitRules.report(grammar, **options)
      Lrama::Trace::Rules.report(grammar, **options)
      Lrama::Trace::Actions.report(grammar, **options)
    end
  end
end
