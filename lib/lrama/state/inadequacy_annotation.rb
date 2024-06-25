module Lrama
  class State
    class InadequacyAnnotation < Struct.new(:token, :action, :item, :contributed, keyword_init: true)
      def no_contributions?
        item.nil? && !contributed
      end
    end
  end
end
