module Lrama
  class Grammar
    class Rule < Struct.new(:id, :lhs, :rhs, :token_code, :nullable, :precedence_sym, :lineno, keyword_init: true)
      attr_accessor :original_rule

      # TODO: Change this to display_name
      def to_s
        l = lhs.id.s_value
        r = rhs.empty? ? "ε" : rhs.map {|r| r.id.s_value }.join(", ")

        "#{l} -> #{r}"
      end

      # Used by #user_actions
      def as_comment
        l = lhs.id.s_value
        r = rhs.empty? ? "%empty" : rhs.map(&:display_name).join(" ")

        "#{l}: #{r}"
      end

      # opt_nl: ε     <-- empty_rule
      #       | '\n'  <-- not empty_rule
      def empty_rule?
        rhs.empty?
      end

      def precedence
        precedence_sym&.precedence
      end

      def initial_rule?
        id == 0
      end

      def translated_code
        return nil unless token_code

        Code::RuleAction.new(type: :rule_action, token_code: token_code).translated_code
      end
    end
  end
end
