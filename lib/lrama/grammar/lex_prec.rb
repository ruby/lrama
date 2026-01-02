# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    # Represents lexical precedence rules defined by %lex-prec directive
    # Based on Definition 3.2.3, 3.2.4, 3.2.10 from the PSLR dissertation
    #
    # Example: %lex-prec RANGLE -s RSHIFT    # RANGLE is shorter than RSHIFT
    #          %lex-prec IF - ID             # IF has higher priority than ID (same length)
    class LexPrec
      # Precedence relation types
      # ","  : Same priority (lex-tie)
      # "-"  : Left has higher priority than right
      # "-s" : Left is shorter match priority over right
      SAME_PRIORITY = :same      #: Symbol
      HIGHER = :higher           #: Symbol
      SHORTER = :shorter         #: Symbol

      # Represents a single precedence rule
      class Rule
        attr_reader :left_token #: Lexer::Token::Ident
        attr_reader :operator #: Symbol
        attr_reader :right_token #: Lexer::Token::Ident
        attr_reader :lineno #: Integer

        # @rbs (left_token: Lexer::Token::Ident, operator: Symbol, right_token: Lexer::Token::Ident, lineno: Integer) -> void
        def initialize(left_token:, operator:, right_token:, lineno:)
          @left_token = left_token
          @operator = operator
          @right_token = right_token
          @lineno = lineno
        end

        # @rbs () -> String
        def left_name
          @left_token.s_value
        end

        # @rbs () -> String
        def right_name
          @right_token.s_value
        end
      end

      attr_reader :rules #: Array[Rule]

      # @rbs () -> void
      def initialize
        @rules = []
      end

      # @rbs (left_token: Lexer::Token::Ident, operator: Symbol, right_token: Lexer::Token::Ident, lineno: Integer) -> Rule
      def add_rule(left_token:, operator:, right_token:, lineno:)
        rule = Rule.new(
          left_token: left_token,
          operator: operator,
          right_token: right_token,
          lineno: lineno
        )
        @rules << rule
        rule
      end

      # Check if token t1 has higher priority than t2
      # Based on Definition 3.2.4
      # @rbs (String t1, String t2) -> bool
      def higher_priority?(t1, t2)
        @rules.any? do |rule|
          rule.operator == HIGHER &&
            rule.left_name == t1 &&
            rule.right_name == t2
        end
      end

      # Check if token t1 has shorter-match priority over t2
      # Based on Definition 3.2.15
      # @rbs (String t1, String t2) -> bool
      def shorter_priority?(t1, t2)
        @rules.any? do |rule|
          rule.operator == SHORTER &&
            rule.left_name == t1 &&
            rule.right_name == t2
        end
      end

      # Check if tokens t1 and t2 are in a lex-tie relationship
      # @rbs (String t1, String t2) -> bool
      def same_priority?(t1, t2)
        @rules.any? do |rule|
          rule.operator == SAME_PRIORITY &&
            ((rule.left_name == t1 && rule.right_name == t2) ||
             (rule.left_name == t2 && rule.right_name == t1))
        end
      end
    end
  end
end
