# frozen_string_literal: true

require_relative "table"
require_relative "javascript/reference_translator"

module Lrama
  module Backend
    class JavaScript < Table
      def file_extension
        "mjs"
      end

      def template_file
        File.join(template_dir, "javascript/parser.mjs.erb")
      end

      def translator
        @translator ||= ReferenceTranslator.new
      end

      def format_int_array(ary)
        "[#{ary.join(', ')}]"
      end

      def format_string_array(ary)
        "[#{ary.map { |s| string_literal(s) }.join(', ')}]"
      end

      def int_type_for(ary)
        min = ary.min
        max = ary.max

        case
        when (-128 <= min && min <= 127) && (-128 <= max && max <= 127)
          "Int8Array"
        when (0 <= min && min <= 255) && (0 <= max && max <= 255)
          "Uint8Array"
        when (-32768 <= min && min <= 32767) && (-32768 <= max && max <= 32767)
          "Int16Array"
        when (0 <= min && min <= 65535) && (0 <= max && max <= 65535)
          "Uint16Array"
        else
          "Int32Array"
        end
      end

      def render_token_definitions
        context.yytokentype.map do |s_value, token_id, display_name|
          "export const #{token_constant_name(s_value)} = #{token_id};#{render_c_style_token_comment(display_name)}\n"
        end.join
      end

      def render_symbol_definitions
        context.yysymbol_kind_t.map do |s_value, sym_number, display_name|
          "const #{sanitized_identifier(s_value)} = #{sym_number};#{render_c_style_token_comment(display_name)}\n"
        end.join
      end

      def render_user_actions(_grammar_file_path)
        action_rules.map do |rule|
          <<-JS
      case #{rule.id + 1}: { // #{rule.as_comment}
#{indent(translated_rule_code(rule), 8)}
        break;
      }
          JS
        end.join
      end
    end

    register(:javascript, JavaScript)
  end
end
