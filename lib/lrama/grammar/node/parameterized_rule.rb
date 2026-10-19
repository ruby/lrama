# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    module Node
      class ParameterizedRule < Base
        attr_reader :name #: String
        attr_reader :parameters #: Array[Lexer::Token::Base]
        attr_reader :tag #: Lexer::Token::Tag?
        attr_reader :rhs_list #: Array[Array[Node::Base]]
        attr_reader :is_inline #: bool

        # @rbs (name: String, parameters: Array[Lexer::Token::Base], ?tag: Lexer::Token::Tag?, rhs_list: Array[Array[Node::Base]], is_inline: bool, location: Lexer::Location) -> void
        def initialize(name:, parameters:, tag: nil, rhs_list:, is_inline:, location:)
          @name = name
          @parameters = parameters
          @tag = tag
          @rhs_list = rhs_list
          @is_inline = is_inline
          super(location: location)
        end
      end
    end
  end
end
