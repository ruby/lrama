# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class State
    class ReduceReduceConflict < Struct.new(:symbols, :reduce1, :reduce2, keyword_init: true)
      # @rbs!
      #   attr_accessor symbols: Array[Grammar::Symbol]
      #   attr_accessor reduce1: State::Action::Reduce
      #   attr_accessor reduce2: State::Action::Reduce
      #
      #   def initialize: (?symbols: Array[Grammar::Symbol], ?reduce1: State::Action::Reduce, ?reduce2: State::Action::Reduce) -> void

      # @rbs () -> :reduce_reduce
      def type
        :reduce_reduce
      end
    end
  end
end
