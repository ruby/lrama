# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class State
    # * symbol: A symbol under discussion
    # * reduce: A reduce under discussion
    # * which: For which a conflict is resolved. :shift, :reduce or :error (for nonassociative)
    class ResolvedConflict < Struct.new(:symbol, :reduce, :which, :same_prec, keyword_init: true)
      # @rbs!
      #   attr_accessor symbol: Grammar::Symbol
      #   attr_accessor reduce: State::Reduce
      #   attr_accessor which: (:reduce | :shift)
      #   attr_accessor same_prec: bool
      #
      #   def initialize: (?symbol: Grammar::Symbol, ?reduce: State::Reduce, ?which: (:reduce | :shift), ?same_prec: bool) -> void

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
