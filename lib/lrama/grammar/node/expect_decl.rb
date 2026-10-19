# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    module Node
      class ExpectDecl < Base
        attr_reader :number #: Integer

        # @rbs (number: Integer, location: Lexer::Location) -> void
        def initialize(number:, location:)
          @number = number
          super(location: location)
        end
      end
    end
  end
end
