# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    module Node
      class Token < Base
        attr_reader :id #: Lexer::Token::Base
        attr_reader :token_id #: Integer?
        attr_reader :alias_name #: String?
        attr_accessor :tag #: Lexer::Token::Tag?

        # @rbs (id: Lexer::Token::Base, ?token_id: Integer?, ?alias_name: String?, ?tag: Lexer::Token::Tag?, location: Lexer::Location) -> void
        def initialize(id:, token_id: nil, alias_name: nil, tag: nil, location:)
          @id = id
          @token_id = token_id
          @alias_name = alias_name
          @tag = tag
          super(location: location)
        end
      end
    end
  end
end
