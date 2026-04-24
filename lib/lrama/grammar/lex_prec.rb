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
      # Precedence relation types (legacy)
      SAME_PRIORITY = :same      #: Symbol
      HIGHER = :higher           #: Symbol
      SHORTER = :shorter         #: Symbol

      # PSLR lex-prec operator types
      # <~  identity conflict: right token wins; length conflict: longest wins
      # <-  identity conflict: right token wins
      # -~  length conflict: longest wins
      # <<  identity and length conflicts: right token wins
      # -<  length conflict: right token wins
      # <s  identity conflict: right token wins; length conflict: shortest wins
      # -s  length conflict: shortest wins
      IDENTITY_RIGHT_LONGEST = :identity_right_longest   #: Symbol
      IDENTITY_RIGHT = :identity_right                   #: Symbol
      LONGEST = :longest                                 #: Symbol
      TOKEN_RIGHT = :token_right                         #: Symbol
      TOKEN_RIGHT_LENGTH = :token_right_length           #: Symbol
      IDENTITY_RIGHT_SHORTEST = :identity_right_shortest #: Symbol
      SHORTEST = :shortest_op                            #: Symbol

      IDENTITY_OPERATORS = [IDENTITY_RIGHT_LONGEST, IDENTITY_RIGHT, TOKEN_RIGHT, IDENTITY_RIGHT_SHORTEST].freeze #: Array[Symbol]
      LENGTH_OPERATORS = [IDENTITY_RIGHT_LONGEST, LONGEST, TOKEN_RIGHT, TOKEN_RIGHT_LENGTH, IDENTITY_RIGHT_SHORTEST, SHORTEST].freeze #: Array[Symbol]
      LONGEST_OPERATORS = [IDENTITY_RIGHT_LONGEST, LONGEST].freeze #: Array[Symbol]
      SHORTEST_OPERATORS = [IDENTITY_RIGHT_SHORTEST, SHORTEST].freeze #: Array[Symbol]
      RIGHT_TOKEN_LENGTH_OPERATORS = [TOKEN_RIGHT, TOKEN_RIGHT_LENGTH].freeze #: Array[Symbol]

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

      # True when winner explicitly wins an identity conflict against loser.
      # The relation is intentionally not transitive.
      # @rbs (String winner, String loser, ?track: bool) -> bool
      def identity_precedes?(winner, loser, track: false)
        @rules.any? do |rule|
          IDENTITY_OPERATORS.include?(rule.operator) &&
            rule.left_name == loser &&
            rule.right_name == winner
        end
      end

      # True when rule declares a longest-match length relation for the pair.
      # @rbs (String token1, String token2) -> bool
      def longest_pair?(token1, token2)
        pair_rule?(token1, token2, LONGEST_OPERATORS)
      end

      # True when rule declares a shortest-match length relation for the pair.
      # @rbs (String token1, String token2) -> bool
      def shortest_pair?(token1, token2)
        pair_rule?(token1, token2, SHORTEST_OPERATORS)
      end

      # Returns the explicit right-token length winner for a pair, if any.
      # @rbs (String token1, String token2) -> String?
      def right_token_length_winner(token1, token2)
        @rules.each do |rule|
          next unless RIGHT_TOKEN_LENGTH_OPERATORS.include?(rule.operator)
          if (rule.left_name == token1 && rule.right_name == token2) ||
             (rule.left_name == token2 && rule.right_name == token1)
            return rule.right_name
          end
        end
        nil
      end

      private

      # @rbs (String token1, String token2, Array[Symbol] operators) -> bool
      def pair_rule?(token1, token2, operators)
        @rules.any? do |rule|
          operators.include?(rule.operator) &&
            ((rule.left_name == token1 && rule.right_name == token2) ||
             (rule.left_name == token2 && rule.right_name == token1))
        end
      end
    end
  end
end
