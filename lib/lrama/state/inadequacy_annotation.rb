module Lrama
  class State
    class InadequacyAnnotation
      attr_accessor :state, :token, :action, :matrix

      def initialize(state, token, action, matrix)
        @state = state
        @token = token
        @action = action
        @matrix = matrix
      end

      def ==(other)
        @state == other.state && @token == other.token && @action == other.action && @matrix == other.matrix
      end
    end
  end
end
