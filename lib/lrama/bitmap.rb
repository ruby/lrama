# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  module Bitmap
    # @rbs!
    #   type bitmap = Integer

    # @rbs (Array[Integer] ary) -> bitmap
    def self.from_array(ary)
      bit = 0

      ary.each do |int|
        bit |= (1 << int)
      end

      bit
    end

    # @rbs (Integer int) -> bitmap
    def self.from_integer(int)
      1 << int
    end

    # @rbs (bitmap int) -> Array[Integer]
    def self.to_array(int)
      a = [] #: Array[Integer]
      i = 0

      while int > 0 do
        if int & 1 == 1
          a << i
        end

        i += 1
        int >>= 1
      end

      a
    end

    # @rbs (bitmap int, Integer size) -> Array[bool]
    def self.to_bool_array(int, size)
      a = Array.new(size) #: Array[bool]

      size.times do |i|
        a[i] = int[i] == 1
      end

      a
    end
  end
end
