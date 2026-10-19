# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    module Node
      module RuleRhs
        class Action < Node::Base
          attr_reader :code #: Lexer::Token::UserCode
          attr_reader :alias_name #: String?
          attr_reader :tag #: Lexer::Token::Tag?

          # @rbs (code: Lexer::Token::UserCode, ?alias_name: String?, ?tag: Lexer::Token::Tag?, location: Lexer::Location) -> void
          def initialize(code:, alias_name: nil, tag: nil, location:)
            @code = code
            @alias_name = alias_name
            @tag = tag
            super(location: location)
          end
        end
      end
    end
  end
end
