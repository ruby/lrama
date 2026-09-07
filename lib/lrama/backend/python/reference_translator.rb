# frozen_string_literal: true

module Lrama
  module Backend
    class Python < Table
      class ReferenceTranslator < Backend::ReferenceTranslator
        private

        def translate_lhs_value(_ref, _rule, _grammar)
          "p[0]"
        end

        def translate_lhs_location(_ref, _rule, _grammar)
          "loc[0]"
        end

        def translate_lhs_index(_ref, _rule, _grammar)
          raise "$:$ is not supported"
        end

        def translate_rhs_value(ref, _rule, _grammar)
          "p[#{ref.index}]"
        end

        def translate_rhs_location(ref, _rule, _grammar)
          "loc[#{ref.index}]"
        end

        def translate_rhs_index(ref, _rule, _grammar)
          "(#{ref.index} - 1)"
        end
      end
    end
  end
end
