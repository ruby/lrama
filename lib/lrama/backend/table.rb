# frozen_string_literal: true

require_relative "base"

module Lrama
  module Backend
    class Table < Base
      def token_enums
        render_token_definitions
      end

      def symbol_enum
        render_symbol_definitions
      end

      def render_symbol_actions_for_printer(_grammar_file_path)
        ""
      end

      def render_symbol_actions_for_destructor(_grammar_file_path)
        ""
      end

      def render_symbol_actions_for_error_token(_grammar_file_path)
        ""
      end

      def render_user_actions(_grammar_file_path)
        ""
      end

      private

      def action_rules
        context.states.rules.select(&:token_code)
      end

      def translated_rule_code(rule)
        rule.translated_code(grammar, translator)
      end

      def indent(code, size)
        padding = " " * size
        code.lines.map { |line| "#{padding}#{line}" }.join
      end

      def escaped_string(string)
        string.to_s
              .gsub("\\", "\\\\\\\\")
              .gsub("\"", "\\\"")
              .gsub("\n", "\\n")
              .gsub("\r", "\\r")
              .gsub("\t", "\\t")
      end

      def string_literal(string)
        "\"#{escaped_string(string)}\""
      end

      def sanitized_identifier(name)
        identifier = name.to_s.gsub(/\W+/, "_")
        identifier = "_#{identifier}" unless identifier.match?(/\A[A-Za-z_]/)
        identifier
      end

      def token_constant_name(name)
        "TOKEN_#{sanitized_identifier(name).upcase}"
      end

      def render_token_comment(display_name)
        display_name ? " # #{display_name}" : ""
      end

      def render_c_style_token_comment(display_name)
        display_name ? " /* #{display_name} */" : ""
      end
    end
  end
end
