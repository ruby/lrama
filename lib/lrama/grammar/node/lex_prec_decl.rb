# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    module Node
      class LexPrecDecl < Base
        attr_reader :left #: Lexer::Token::Base
        attr_reader :operator #: ::Symbol
        attr_reader :right #: Lexer::Token::Base

        # @rbs (left: Lexer::Token::Base, operator: ::Symbol, right: Lexer::Token::Base, location: Lexer::Location) -> void
        def initialize(left:, operator:, right:, location:)
          @left = left
          @operator = operator
          @right = right
          super(location: location)
        end
      end
    end
  end
end
