# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class State
    class Action
      class Shift
        # TODO: rbs-inline 0.10.0 doesn't support instance variables.
        #       Move these type declarations above instance variable definitions, once it's supported.
        #
        # @rbs!
        #   @next_sym: Grammar::Symbol
        #   @next_items: Array[States::Item]

        attr_reader :next_sym #: Grammar::Symbol
        attr_reader :next_items #: Array[States::Item]
        attr_accessor :not_selected #: bool

        # @rbs (Grammar::Symbol next_sym, Array[States::Item] next_items) -> void
        def initialize(next_sym, next_items)
          @next_sym = next_sym
          @next_items = next_items
        end
      end
    end
  end
end
