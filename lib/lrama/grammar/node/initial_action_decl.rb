# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    module Node
      class InitialActionDecl < Base
        attr_reader :code #: Lexer::Token::UserCode

        # @rbs (code: Lexer::Token::UserCode, location: Lexer::Location) -> void
        def initialize(code:, location:)
          @code = code
          super(location: location)
        end
      end
    end
  end
end
