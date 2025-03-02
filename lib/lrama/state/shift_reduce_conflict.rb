# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class State
    class ShiftReduceConflict < Struct.new(:symbols, :shift, :reduce, keyword_init: true)
      # @rbs!
      #   attr_accessor symbols: Array[Grammar::Symbol]
      #   attr_accessor shift: State::Action::Shift | State::Action::Goto
      #   attr_accessor reduce: State::Action::Reduce
      #
      #   def initialize: (?symbols: Array[Grammar::Symbol], ?shift: State::Action::Shift, ?reduce: State::Action::Reduce) -> void

      # @rbs () -> :shift_reduce
      def type
        :shift_reduce
      end
    end
  end
end
