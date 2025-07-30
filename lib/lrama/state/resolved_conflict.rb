# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class State
    # * symbol: A symbol under discussion
    # * reduce: A reduce under discussion
    # * which: For which a conflict is resolved. :shift, :reduce or :error (for nonassociative)
    # * resolved_by_precedence: If the conflict is resolved by precedence definition or not
    class ResolvedConflict
      # @rbs!
      #   type which_enum = :reduce | :shift | :error

      attr_reader :symbol #: Grammar::Symbol
      attr_reader :reduce #: State::Action::Reduce
      attr_reader :which #: which_enum
      attr_reader :resolved_by_precedence #: bool

      # @rbs (symbol: Grammar::Symbol, reduce: State::Action::Reduce, which: which_enum, resolved_by_precedence: bool) -> void
      def initialize(symbol:, reduce:, which:, resolved_by_precedence:)
        @symbol = symbol
        @reduce = reduce
        @which = which
        @resolved_by_precedence = resolved_by_precedence
      end

      # @rbs () -> (::String | bot)
      def report_message
        s = symbol.display_name
        r = reduce.rule.precedence_sym&.display_name
        case
        when which == :shift && resolved_by_precedence
          msg = "resolved as #{which} (%right #{s})"
        when which == :shift
          msg = "resolved as #{which} (#{r} < #{s})"
        when which == :reduce && resolved_by_precedence
          msg = "resolved as #{which} (%left #{s})"
        when which == :reduce
          msg = "resolved as #{which} (#{s} < #{r})"
        when which == :error
          msg = "resolved as an #{which} (%nonassoc #{s})"
        else
          raise "Unknown direction. #{self}"
        end

        "Conflict between rule #{reduce.rule.id} and token #{s} #{msg}."
      end
    end
  end
end
