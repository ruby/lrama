# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    class Union < Struct.new(:code, :lineno, keyword_init: true)
      # @rbs!
      #   attr_accessor code: Grammar::Code::NoReferenceCode
      #   attr_accessor lineno: Integer
      #
      #   def initialize: (?code: Grammar::Code::NoReferenceCode, ?lineno: Integer) -> void

      # @rbs () -> String
      def braces_less_code
        # Braces is already removed by lexer
        code.s_value
      end
    end
  end
end
