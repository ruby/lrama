# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    module Node
      class ParseParamDecl < Base
        attr_reader :params #: Array[Lexer::Token::UserCode]

        # @rbs (params: Array[Lexer::Token::UserCode], location: Lexer::Location) -> void
        def initialize(params:, location:)
          @params = params
          super(location: location)
        end
      end
    end
  end
end
