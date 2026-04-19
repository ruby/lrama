# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    # Represents scoped lexical declarations defined by %lex-scope directive.
    #
    # Scoped declarations allow lexical precedence and tie rules to apply
    # only when parsing within the scope of a particular nonterminal.
    #
    # Example:
    #   %lex-scope template_args {
    #     %lex-prec RANGLE -~ RSHIFT
    #   }
    class ScopedLexDecl
      attr_reader :scope_name #: String
      attr_reader :lex_prec_rules #: Array[LexPrec::Rule]
      attr_reader :lex_tie_declarations #: Array[LexTie::Declaration]
      attr_reader :lineno #: Integer

      # @rbs (scope_name: String, lineno: Integer) -> void
      def initialize(scope_name:, lineno:)
        @scope_name = scope_name
        @lex_prec_rules = []
        @lex_tie_declarations = []
        @lineno = lineno
      end

      # @rbs (LexPrec::Rule rule) -> void
      def add_lex_prec_rule(rule)
        @lex_prec_rules << rule
      end

      # @rbs (LexTie::Declaration declaration) -> void
      def add_lex_tie_declaration(declaration)
        @lex_tie_declarations << declaration
      end
    end
  end
end
