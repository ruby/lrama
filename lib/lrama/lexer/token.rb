require 'lrama/lexer/token/type'

module Lrama
  class Lexer
    class Token

      attr_accessor :line, :column, :referred
      # For User_code
      attr_accessor :references

      def to_s
        "#{super} line: #{line}, column: #{column}"
      end

      def referred_by?(string)
        [self.s_value, self.alias].include?(string)
      end

      def ==(other)
        self.class == other.class && self.type == other.type && self.s_value == other.s_value
      end

      @i = 0
      @types = []

      def self.define_type(name)
        type = Type.new(id: @i, name: name.to_s)
        const_set(name, type)
        @types << type
        @i += 1
      end

      # Token types
      define_type(:User_code)        # { ... }
      define_type(:Tag)              # <int>
      define_type(:Ident)            # api.pure, tNUMBER
      define_type(:Char)             # '+'
    end
  end
end
