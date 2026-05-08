# rbs_inline: enabled
# frozen_string_literal: true

require "json"

require_relative "../diagnostic"

module Lrama
  class Reporter
    class JSON
      # @rbs (Array[Lrama::Diagnostic] diagnostics) -> String
      def report(diagnostics)
        ::JSON.pretty_generate(
          "diagnostics" => diagnostics.map(&:to_h)
        )
      end
    end
  end
end
