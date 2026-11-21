# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Lexer
    module Token
      # Token class for regex patterns used in %token-pattern directive
      # Example: /[a-zA-Z_][a-zA-Z0-9_]*/
      class Regex < Base
        # Returns the regex pattern without the surrounding slashes
        # @rbs () -> String
        def pattern
          # Remove leading and trailing slashes
          s_value[1..-2].to_s
        end
      end
    end
  end
end
