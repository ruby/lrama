# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    module Node
      class Rule < Base
        attr_reader :id #: Lexer::Token::Base
        attr_reader :alias_name #: String?
        attr_reader :rhs #: Array[Node::Base]

        # @rbs (id: Lexer::Token::Base, ?alias_name: String?, rhs: Array[Node::Base], location: Lexer::Location) -> void
        def initialize(id:, alias_name: nil, rhs:, location:)
          @id = id
          @alias_name = alias_name
          @rhs = rhs
          super(location: location)
        end
      end
    end
  end
end
