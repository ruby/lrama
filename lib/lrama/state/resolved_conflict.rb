# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class State
    # * symbol: A symbol under discussion
    # * reduce: A reduce under discussion
    # * which: For which a conflict is resolved. :shift, :reduce or :error (for nonassociative)
    class ResolvedConflict
      attr_reader :symbol #: Grammar::Symbol
      attr_reader :reduce #: State::Action::Reduce
      attr_reader :which #: (:reduce | :shift | :error)
      attr_reader :same_prec #: bool

      # @rbs (symbol: Grammar::Symbol, reduce: State::Action::Reduce, which: (:reduce | :shift | :error), ?same_prec: bool) -> void
      def initialize(symbol:, reduce:, which:, same_prec: false)
        @symbol = symbol
        @reduce = reduce
        @which = which
        @same_prec = same_prec
      end

      # @rbs () -> (::String | bot)
      def report_message
        s = symbol.display_name
        r = reduce.rule.precedence_sym&.display_name
        case
        when which == :shift && same_prec
          msg = "resolved as #{which} (%right #{s})"
        when which == :shift
          msg = "resolved as #{which} (#{r} < #{s})"
        when which == :reduce && same_prec
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
