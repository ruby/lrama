module Lrama
  class Rule < Struct.new(:id, :lhs, :rhs, :code, :nullable, :precedence_sym, :lineno, keyword_init: true)
    # TODO: Change this to display_name
    def to_s
      l = lhs.id.s_value
      r = rhs.empty? ? "ε" : rhs.map {|r| r.id.s_value }.join(", ")

      "#{l} -> #{r}"
    end

    # Used by #user_actions
    def as_comment
      l = lhs.id.s_value
      r = rhs.empty? ? "%empty" : rhs.map {|r| r.display_name }.join(" ")

      "#{l}: #{r}"
    end

    def precedence
      precedence_sym && precedence_sym.precedence
    end

    def initial_rule?
      id == 0
    end

    def translated_code
      if code
        code.translated_code
      else
        nil
      end
    end
  end
end
