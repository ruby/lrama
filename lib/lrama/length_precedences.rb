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

    class LexicalPrecedenceConflictError < StandardError; end

    class RuleSource
      attr_reader :operator #: Symbol
      attr_reader :lineno #: Integer

      # @rbs (Symbol operator, Integer lineno) -> void
      def initialize(operator, lineno)
        @operator = operator
        @lineno = lineno
      end
    end

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

    # @rbs (String old_token, String new_token, ?fallback: bool) -> Symbol
    def resolution(old_token, new_token, fallback: false)
      @resolution_table.fetch([old_token, new_token]) do
        return PREFER_NEW if old_token == new_token
        return PREFER_NEW if fallback

        UNRESOLVED
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
      sources = {}

      lex_prec.rules.each do |rule|
        left = rule.left_name
        right = rule.right_name

        case rule.operator
        when Grammar::LexPrec::IDENTITY_RIGHT_LONGEST, Grammar::LexPrec::LONGEST
          set_resolution!(table, sources, [left, right], PREFER_NEW, rule)
          set_resolution!(table, sources, [right, left], PREFER_NEW, rule)
        when Grammar::LexPrec::IDENTITY_RIGHT_SHORTEST, Grammar::LexPrec::SHORTEST
          set_resolution!(table, sources, [left, right], PREFER_OLD, rule)
          set_resolution!(table, sources, [right, left], PREFER_OLD, rule)
        when Grammar::LexPrec::TOKEN_RIGHT, Grammar::LexPrec::TOKEN_RIGHT_LENGTH
          set_resolution!(table, sources, [left, right], PREFER_NEW, rule)
          set_resolution!(table, sources, [right, left], PREFER_OLD, rule)
        end
      end

      table
    end

    # @rbs (Hash[[String, String], Symbol] table, Hash[[String, String], RuleSource] sources, [String, String] key, Symbol value, Grammar::LexPrec::Rule rule) -> void
    def set_resolution!(table, sources, key, value, rule)
      existing = table[key]
      if existing.nil?
        table[key] = value
        sources[key] = RuleSource.new(rule.operator, rule.lineno)
        return
      end

      return if existing == value

      source = sources.fetch(key)
      old_token, new_token = key
      raise LexicalPrecedenceConflictError,
        "conflicting %lex-prec length rules for #{old_token} -> #{new_token}: " \
        "#{operator_label(source.operator)} at line #{source.lineno} resolves #{resolution_label(existing)}, " \
        "but #{operator_label(rule.operator)} at line #{rule.lineno} resolves #{resolution_label(value)}"
    end

    # @rbs (Symbol operator) -> String
    def operator_label(operator)
      case operator
      when Grammar::LexPrec::IDENTITY_RIGHT_LONGEST
        "<~"
      when Grammar::LexPrec::IDENTITY_RIGHT
        "<-"
      when Grammar::LexPrec::LONGEST
        "-~"
      when Grammar::LexPrec::TOKEN_RIGHT
        "<<"
      when Grammar::LexPrec::TOKEN_RIGHT_LENGTH
        "-<"
      when Grammar::LexPrec::IDENTITY_RIGHT_SHORTEST
        "<s"
      when Grammar::LexPrec::SHORTEST
        "-s"
      else
        operator.to_s
      end
    end

    # @rbs (Symbol value) -> String
    def resolution_label(value)
      case value
      when PREFER_NEW
        "prefer-new"
      when PREFER_OLD
        "prefer-old"
      else
        value.to_s
      end
    end
  end
end
