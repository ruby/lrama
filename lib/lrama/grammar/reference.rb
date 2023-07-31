# type: :dollar or :at
# ex_tag: "$<tag>1" (Optional)

module Lrama
  class Grammar
    class Reference < Struct.new(:type, :value, :ex_tag, :first_column, :last_column, :referring_symbol, :position_in_rhs, keyword_init: true)
      def tag
        if ex_tag
          ex_tag
        else
          referring_symbol.tag
        end
      end

      def member
        if tag = self.tag
          # Omit "<>"
          tag.s_value[1..-2]
        end
      end
    end
  end
end
