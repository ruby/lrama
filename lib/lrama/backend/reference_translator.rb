# frozen_string_literal: true

module Lrama
  module Backend
    class ReferenceTranslator
      def translate(ref, rule, grammar)
        case
        when ref.type == :dollar && ref.name == "$"
          translate_lhs_value(ref, rule, grammar)
        when ref.type == :at && ref.name == "$"
          translate_lhs_location(ref, rule, grammar)
        when ref.type == :index && ref.name == "$"
          translate_lhs_index(ref, rule, grammar)
        when ref.type == :dollar
          translate_rhs_value(ref, rule, grammar)
        when ref.type == :at
          translate_rhs_location(ref, rule, grammar)
        when ref.type == :index
          translate_rhs_index(ref, rule, grammar)
        else
          raise "Unexpected. #{ref}"
        end
      end

      private

      def translate_lhs_value(_ref, _rule, _grammar)
        raise NotImplementedError
      end

      def translate_lhs_location(_ref, _rule, _grammar)
        raise NotImplementedError
      end

      def translate_lhs_index(_ref, _rule, _grammar)
        raise NotImplementedError
      end

      def translate_rhs_value(_ref, _rule, _grammar)
        raise NotImplementedError
      end

      def translate_rhs_location(_ref, _rule, _grammar)
        raise NotImplementedError
      end

      def translate_rhs_index(_ref, _rule, _grammar)
        raise NotImplementedError
      end
    end
  end
end
