# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  # An OrderedSet is a set that maintains the insertion order of its elements.
  # For example, it can be used in situations like certain fixed-point calculations
  # where you need to manage a queue of objects to be processed,
  # but you want to avoid having duplicate objects within the queue.
  class OrderedSet
    # @rbs!
    #   @array: Array[Object]
    #   @hash: Hash[Object, bool]

    # @rbs () -> void
    def initialize
      @array = []
      @hash = {}
    end

    # @rbs () -> Object?
    def shift
      return nil if @array.empty?

      obj = @array.shift
      @hash.delete(obj)
      obj
    end

    # @rbs (Object) -> bool
    def <<(obj)
      return false if @hash[obj]

      @array << obj
      @hash[obj] = true

      return true
    end

    # @rbs () -> Array[Object]
    def to_a
      @array.dup
    end
  end
end
