module Lrama
  class Precedence < Struct.new(:type, :precedence, keyword_init: true)
    include Comparable

    def <=>(other)
      self.precedence <=> other.precedence
    end
  end
end
