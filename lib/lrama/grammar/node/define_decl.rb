# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    module Node
      class DefineDecl < Base
        attr_reader :variable #: String
        attr_reader :value #: String?

        # @rbs (variable: String, value: String?, location: Lexer::Location) -> void
        def initialize(variable: ,value:, location:)
          @variable = variable
          @value = value
          super(location: location)
        end
      end
    end
  end
end
