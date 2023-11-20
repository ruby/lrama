module Lrama
  class Grammar
    class Attribute
      attr_reader :id, :args

      def initialize(id, args)
        @id = id
        @args = args
      end
    end
  end
end
