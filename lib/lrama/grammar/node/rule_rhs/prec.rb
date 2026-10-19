# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    module Node
      module RuleRhs
        class Prec < Node::Base
          attr_reader :token #: Lexer::Token::Base

          # @rbs (token: Lexer::Token::Base, location: Lexer::Location) -> void
          def initialize(token:, location:)
            @token = token
            super(location: location)
          end
        end
      end
    end
  end
end
