# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Lexer
    module Token
      class SemanticPredicate < Base
        attr_reader :code #: String

        # @rbs (s_value: String, code: String, ?location: Location) -> void
        def initialize(s_value:, code:, location: nil)
          super(s_value: s_value, location: location)
          @code = code.freeze
        end

        # @rbs () -> String
        def to_s
          "semantic_predicate: `{#{code}}?`, location: #{location}"
        end
      end
    end
  end
end
