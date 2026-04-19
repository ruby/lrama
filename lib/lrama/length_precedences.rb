# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  # Runtime length precedence matrix for PSLR pseudo-scanning.
  #
  # When a longer match for new_token is reached after an earlier match for
  # old_token, #precedes? answers whether the longer match should replace it.
  class LengthPrecedences
    LEFT = :left #: Symbol
    RIGHT = :right #: Symbol
    UNDEFINED = :undefined #: Symbol

    PREFER_NEW = :prefer_new #: Symbol
    PREFER_OLD = :prefer_old #: Symbol
    UNRESOLVED = :unresolved #: Symbol

    attr_reader :table #: Hash[[String, String], bool]
    attr_reader :resolution_table #: Hash[[String, String], Symbol]

    # @rbs (Grammar::LexPrec lex_prec) -> void
    def initialize(lex_prec)
      @lex_prec = lex_prec
      @resolution_table = build_resolution_table(lex_prec)
      @table = @resolution_table.transform_values {|value| value == PREFER_NEW }
    end

    # @rbs (String old_token, String new_token) -> bool
    def precedes?(old_token, new_token)
      resolution(old_token, new_token) == PREFER_NEW
    end

    # Backward-compatible query used by existing specs.
    # @rbs (String old_token, String new_token) -> bool
    def prefer_shorter?(old_token, new_token)
      resolution(old_token, new_token) == PREFER_OLD
    end

    # @rbs (String old_token, String new_token) -> Symbol
    def resolution(old_token, new_token)
      @resolution_table.fetch([old_token, new_token]) do
        old_token == new_token ? PREFER_NEW : UNRESOLVED
      end
    end

    # @rbs (String old_token, String new_token) -> Symbol
    def precedence(old_token, new_token)
      case resolution(old_token, new_token)
      when PREFER_NEW
        RIGHT
      when PREFER_OLD
        LEFT
      else
        UNDEFINED
      end
    end

    private

    # @rbs (Grammar::LexPrec lex_prec) -> Hash[[String, String], Symbol]
    def build_resolution_table(lex_prec)
      table = {}

      lex_prec.rules.each do |rule|
        left = rule.left_name
        right = rule.right_name

        case rule.operator
        when Grammar::LexPrec::IDENTITY_RIGHT_LONGEST, Grammar::LexPrec::LONGEST
          table[[left, right]] = PREFER_NEW
          table[[right, left]] = PREFER_NEW
        when Grammar::LexPrec::IDENTITY_RIGHT_SHORTEST, Grammar::LexPrec::SHORTEST
          table[[left, right]] = PREFER_OLD
          table[[right, left]] = PREFER_OLD
        when Grammar::LexPrec::TOKEN_RIGHT, Grammar::LexPrec::TOKEN_RIGHT_LENGTH
          table[[left, right]] = PREFER_NEW
          table[[right, left]] = PREFER_OLD
        end
      end

      table
    end
  end
end
