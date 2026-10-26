# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    module Node
      module RuleRhs
        class InstantiateRule < Node::Base
          attr_reader :name #: String
          attr_reader :args #: Array[Node::RuleRhs::value]
          attr_reader :alias_name #: String?
          attr_reader :lhs_tag #: Lexer::Token::Tag?

          # @rbs (name: String, args: Array[Node::RuleRhs::value], ?alias_name: String?, ?lhs_tag: Lexer::Token::Tag?, location: Lexer::Location) -> void
          def initialize(name:, args:, alias_name: nil, lhs_tag: nil, location:)
            @name = name
            @args = args
            @alias_name = alias_name
            @lhs_tag = lhs_tag
            super(location: location)
          end
        end
      end
    end
  end
end
