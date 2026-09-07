# rbs_inline: enabled
# frozen_string_literal: true

require_relative "../../backend"

module Lrama
  class Grammar
    class Code
      class RuleAction < Code
        # TODO: rbs-inline 0.11.0 doesn't support instance variables.
        #       Move these type declarations above instance variable definitions, once it's supported.
        #       see: https://github.com/soutaro/rbs-inline/pull/149
        #
        # @rbs!
        #   @rule: Rule
        #   @grammar: Grammar

        # @rbs (type: ::Symbol, token_code: Lexer::Token::UserCode, rule: Rule, grammar: Grammar) -> void
        def initialize(type:, token_code:, rule:, grammar:)
          super(type: type, token_code: token_code)
          @rule = rule
          @grammar = grammar
        end

        private

        # * ($$) yyval
        # * (@$) yyloc
        # * ($:$) error
        # * ($1) yyvsp[i]
        # * (@1) yylsp[i]
        # * ($:1) i - 1
        #
        #
        # Consider a rule like
        #
        #   class: keyword_class { $1 } tSTRING { $2 + $3 } keyword_end { $class = $1 + $keyword_end }
        #
        # For the semantic action of original rule:
        #
        # "Rule"                class: keyword_class { $1 } tSTRING { $2 + $3 } keyword_end { $class = $1 + $keyword_end }
        # "Position in grammar"                   $1     $2      $3          $4          $5
        # "Index for yyvsp"                       -4     -3      -2          -1           0
        # "$:n"                                  $:1    $:2     $:3         $:4         $:5
        # "index of $:n"                          -5     -4      -3          -2          -1
        #
        #
        # For the first midrule action:
        #
        # "Rule"                class: keyword_class { $1 } tSTRING { $2 + $3 } keyword_end { $class = $1 + $keyword_end }
        # "Position in grammar"                   $1
        # "Index for yyvsp"                        0
        # "$:n"                                  $:1
        #
        # @rbs (Reference ref) -> String
        def reference_to_c(ref)
          Backend::C::ReferenceTranslator.new.translate(ref, @rule, @grammar)
        end

        # @rbs (Reference ref, untyped translator) -> String
        def translated_reference(ref, translator)
          if translator
            translator.translate(ref, @rule, @grammar)
          else
            reference_to_c(ref)
          end
        end
      end
    end
  end
end
