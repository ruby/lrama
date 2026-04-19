# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  # Length precedences table for PSLR(1)
  # Based on Definition 3.2.15 from the PSLR dissertation
  #
  # Determines which token should be preferred when there's a length conflict:
  # - :left  - the shorter token (t1) should be preferred
  # - :right - the longer token (t2) should be preferred
  # - :undefined - no preference defined, use default (longest match)
  class LengthPrecedences
    # Result of length precedence lookup
    LEFT = :left       #: Symbol
    RIGHT = :right     #: Symbol
    UNDEFINED = :undefined #: Symbol

    attr_reader :table #: Hash[[String, String], Symbol]

    # @rbs (Grammar::LexPrec lex_prec) -> void
    def initialize(lex_prec)
      @table = build_table(lex_prec)
    end

    # Get the length precedence between two tokens
    # @rbs (String t1, String t2) -> Symbol
    def precedence(t1, t2)
      @table[[t1, t2]] || UNDEFINED
    end

    # Check if t1 (shorter) should be preferred over t2 (longer)
    # @rbs (String t1, String t2) -> bool
    def prefer_shorter?(t1, t2)
      precedence(t1, t2) == LEFT
    end

    private

    # Build the length precedence table from lex-prec rules
    # @rbs (Grammar::LexPrec lex_prec) -> Hash[[String, String], Symbol]
    def build_table(lex_prec)
      table = {}

      lex_prec.rules.each do |rule|
        case rule.operator
        when Grammar::LexPrec::SHORTER
          # t1 -s t2: t1 (shorter) should be preferred over t2 (longer)
          table[[rule.left_name, rule.right_name]] = LEFT
          # Inverse: t2 (longer) should not be preferred over t1 (shorter)
          table[[rule.right_name, rule.left_name]] = RIGHT
        end
      end

      table
    end
  end
end
