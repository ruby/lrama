# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Counterexamples
    # s: state
    # itm: item within s
    # l: precise lookahead set
    class Triple < Struct.new(:s, :itm, :l)
      # @rbs!
      #   attr_accessor s: State
      #   attr_accessor itm: States::Item
      #   attr_accessor l: Set[Grammar::Symbol]
      #
      #   def initialize: (State s, States::Item itm, Set[Grammar::Symbol] l) -> void

      alias :state :s
      alias :item :itm
      alias :precise_lookahead_set :l

      # @rbs () -> StateItem
      def state_item
        StateItem.new(state, item)
      end

      # @rbs () -> ::String
      def inspect
        "#{state.inspect}. #{item.display_name}. #{l.map(&:id).map(&:s_value)}"
      end
      alias :to_s :inspect
    end
  end
end
