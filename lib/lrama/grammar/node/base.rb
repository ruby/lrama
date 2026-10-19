# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    module Node
      class Base
        attr_reader :location #: Lexer::Location

        # @rbs (location: Lexer::Location) -> void
        def initialize(location:)
          @location = location
        end

        alias :loc :location
      end
    end
  end
end
