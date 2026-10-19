# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    module Node
      class PrecedenceDecl < Base
        # @rbs!
        #   type type_enum = :left | :right | :precedence | :nonassoc

        attr_reader :type #: type_enum
        attr_reader :tokens #: Array[Node::Token]
        attr_reader :number #: Integer

        # @rbs (type: type_enum, tokens: Array[Node::Token], number: Integer, location: Lexer::Location) -> void
        def initialize(type:, tokens:, number:, location:)
          @type = type
          @tokens = tokens
          @number = number
          super(location: location)
        end
      end
    end
  end
end
