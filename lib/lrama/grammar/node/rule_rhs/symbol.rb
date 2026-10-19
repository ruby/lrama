# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    module Node
      module RuleRhs
        class Symbol < Node::Base
          attr_reader :token #: Lexer::Token::Base
          attr_reader :alias_name #: String?

          # @rbs (token: Lexer::Token::Base, ?alias_name: String?, location: Lexer::Location) -> void
          def initialize(token:, alias_name: nil, location:)
            @token = token
            @alias_name = alias_name
            super(location: location)
          end

          # @rbs () -> String
          def s_value
            @token.s_value
          end
        end
      end
    end
  end
end
