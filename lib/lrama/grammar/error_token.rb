module Lrama
  class Grammar
    class ErrorToken < Struct.new(:ident_or_tags, :code, :lineno, keyword_init: true)
      def translated_code(tag)
        code.tag = tag
        code.translated_code
      end
    end
  end
end
