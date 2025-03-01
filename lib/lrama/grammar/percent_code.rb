# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    class PercentCode
      # TODO: rbs-inline 0.10.0 doesn't support instance variables.
      #       Move these type declarations above instance variable definitions, once it's supported.
      #
      # @rbs!
      #   @name: String
      #   @code: String

      attr_reader :name #: String
      attr_reader :code #: String

      # @rbs (String name, String code) -> void
      def initialize(name, code)
        @name = name
        @code = code
      end
    end
  end
end
