# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    class Precedence < Struct.new(:type, :precedence, :s_value, :lineno, keyword_init: true)
      include Comparable
      # @rbs!
      #   type type_enum = :left | :right | :nonassoc | :precedence
      #
      #   attr_accessor type: type_enum
      #   attr_accessor precedence: Integer
      #   attr_accessor s_value: String
      #   attr_accessor lineno: Integer
      #
      #   def initialize: (?type: type_enum, ?precedence: Integer, ?s_value: ::String, ?lineno: Integer) -> void

      # @rbs (Precedence other) -> Integer
      def <=>(other)
        self.precedence <=> other.precedence
      end
    end
  end
end
