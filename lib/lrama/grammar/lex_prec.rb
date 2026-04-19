# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    # Represents lexical precedence rules defined by %lex-prec.
    #
    # Lrama accepts ASCII spellings for the PSLR paper operators:
    #   <~  identity conflict: right token wins; length conflict: longest wins
    #   <-  identity conflict: right token wins
    #   -~  length conflict: longest wins
    #   <<  identity and length conflicts: right token wins
    #   -<  length conflict: right token wins
    #   <s  identity conflict: right token wins; length conflict: shortest wins
    #   -s  length conflict: shortest wins
    class LexPrec
      IDENTITY_RIGHT_LONGEST = :identity_right_longest #: Symbol
      IDENTITY_RIGHT = :identity_right #: Symbol
      LONGEST = :longest #: Symbol
      TOKEN_RIGHT = :token_right #: Symbol
      TOKEN_RIGHT_LENGTH = :token_right_length #: Symbol
      IDENTITY_RIGHT_SHORTEST = :identity_right_shortest #: Symbol
      SHORTEST = :shortest #: Symbol

      IDENTITY_OPERATORS = [
        IDENTITY_RIGHT_LONGEST,
        IDENTITY_RIGHT,
        TOKEN_RIGHT,
        IDENTITY_RIGHT_SHORTEST
      ].freeze #: Array[Symbol]

      LENGTH_OPERATORS = [
        IDENTITY_RIGHT_LONGEST,
        LONGEST,
        TOKEN_RIGHT,
        TOKEN_RIGHT_LENGTH,
        IDENTITY_RIGHT_SHORTEST,
        SHORTEST
      ].freeze #: Array[Symbol]

      LONGEST_OPERATORS = [
        IDENTITY_RIGHT_LONGEST,
        LONGEST
      ].freeze #: Array[Symbol]

      SHORTEST_OPERATORS = [
        IDENTITY_RIGHT_SHORTEST,
        SHORTEST
      ].freeze #: Array[Symbol]

      RIGHT_TOKEN_LENGTH_OPERATORS = [
        TOKEN_RIGHT,
        TOKEN_RIGHT_LENGTH
      ].freeze #: Array[Symbol]

      # Raw declaration stored before operand expansion.
      # Operands may be :token, :symbol_set, or :yyall.
      class Declaration
        attr_reader :left_operand #: Lexer::Token::Base
        attr_reader :operator #: Symbol
        attr_reader :right_operand #: Lexer::Token::Base
        attr_reader :lineno #: Integer

        # @rbs (left_operand: Lexer::Token::Base, operator: Symbol, right_operand: Lexer::Token::Base, lineno: Integer) -> void
        def initialize(left_operand:, operator:, right_operand:, lineno:)
          @left_operand = left_operand
          @operator = operator
          @right_operand = right_operand
          @lineno = lineno
        end
      end

      class Rule
        attr_reader :left_token #: Lexer::Token::Base
        attr_reader :operator #: Symbol
        attr_reader :right_token #: Lexer::Token::Base
        attr_reader :lineno #: Integer

        # @rbs (left_token: Lexer::Token::Base, operator: Symbol, right_token: Lexer::Token::Base, lineno: Integer) -> void
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
      attr_reader :declarations #: Array[Declaration]

      # @rbs () -> void
      def initialize
        @rules = []
        @declarations = []
      end

      # Store a raw declaration for delayed expansion.
      # @rbs (left_operand: Lexer::Token::Base, operator: Symbol, right_operand: Lexer::Token::Base, lineno: Integer) -> Declaration
      def add_declaration(left_operand:, operator:, right_operand:, lineno:)
        decl = Declaration.new(
          left_operand: left_operand,
          operator: operator,
          right_operand: right_operand,
          lineno: lineno
        )
        @declarations << decl
        decl
      end

      # @rbs (left_token: Lexer::Token::Base, operator: Symbol, right_token: Lexer::Token::Base, lineno: Integer) -> Rule
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

      # True when winner explicitly wins an identity conflict against loser.
      # The relation is intentionally not transitive.
      # @rbs (String winner, String loser) -> bool
      def identity_precedes?(winner, loser)
        return true if winner == loser

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
        rule = @rules.find do |r|
          RIGHT_TOKEN_LENGTH_OPERATORS.include?(r.operator) &&
            ((r.left_name == token1 && r.right_name == token2) ||
             (r.left_name == token2 && r.right_name == token1))
        end

        rule&.right_name
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
