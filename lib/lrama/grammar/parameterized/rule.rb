# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    class Parameterized
      class Rule
        attr_reader :name #: String
        attr_reader :parameters #: Array[Lexer::Token]
        attr_reader :rhs_list #: Array[Rhs]
        attr_reader :required_parameters_count #: Integer
        attr_reader :tag #: Lexer::Token::Tag?
        attr_reader :is_inline #: bool

        # @rbs (String name, Array[Lexer::Token] parameters, Array[Rhs] rhs_list, tag: Lexer::Token::Tag?, is_inline: bool) -> void
        def initialize(name, parameters, rhs_list, tag: nil, is_inline: false)
          @name = name
          @parameters = parameters
          @rhs_list = rhs_list
          @tag = tag
          @is_inline = is_inline
          @required_parameters_count = parameters.count
        end

        # @rbs () -> String
        def to_s
          "#{@name}(#{@parameters.map(&:s_value).join(', ')})"
        end
      end
    end
  end
end
