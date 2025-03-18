# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    # Grammar file information not used by States but by Output
    class Auxiliary < Struct.new(:prologue_first_lineno, :prologue, :epilogue_first_lineno, :epilogue, keyword_init: true)
      # @rbs!
      #   attr_accessor prologue_first_lineno: Integer
      #   attr_accessor prologue: String
      #   attr_accessor epilogue_first_lineno: Integer
      #   attr_accessor epilogue: String
      #
      #   def initialize: (?prologue_first_lineno: Integer, ?prologue: String, ?epilogue_first_lineno: Integer, ?epilogue: String) -> void
    end
  end
end
