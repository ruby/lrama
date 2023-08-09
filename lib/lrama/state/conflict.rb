module Lrama
  class State
    class Conflict < Struct.new(:symbols, :reduce, :type, keyword_init: true)
    end
  end
end
