# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    module Node
      class Symbol < Base
        attr_reader :id #: Lexer::Token::Base
        attr_accessor :tag #: Lexer::Token::Tag?

        # @rbs (id: Lexer::Token::Base, ?tag: Lexer::Token::Tag?, location: Lexer::Location) -> void
        def initialize(id:, tag: nil, location:)
          @id = id
          @tag = tag
          super(location: location)
        end
      end
    end
  end
end
