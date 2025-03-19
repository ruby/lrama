# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    class Precedence < Struct.new(:type, :precedence, keyword_init: true)
      include Comparable
      # @rbs!
      #   attr_accessor type: ::Symbol
      #   attr_accessor precedence: Integer
      #
      #   def initialize: (?type: ::Symbol, ?precedence: Integer) -> void

      # @rbs (Precedence other) -> Integer
      def <=>(other)
        self.precedence <=> other.precedence
      end
    end
  end
end
