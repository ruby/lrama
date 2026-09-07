# frozen_string_literal: true

require_relative "table"
require_relative "cpp/reference_translator"

module Lrama
  module Backend
    class Cpp < Table
      def file_extension
        "cpp"
      end

      def template_file
        File.join(template_dir, "cpp/parser.cpp.erb")
      end

      def translator
        @translator ||= ReferenceTranslator.new
      end

      def format_int_array(ary)
        "{#{ary.join(', ')}}"
      end

      def format_string_array(ary)
        "{#{ary.map { |s| string_literal(s) }.join(', ')}}"
      end

      def int_type_for(ary)
        min = ary.min
        max = ary.max

        case
        when (-128 <= min && min <= 127) && (-128 <= max && max <= 127)
          "std::int8_t"
        when (0 <= min && min <= 255) && (0 <= max && max <= 255)
          "std::uint8_t"
        when (-32768 <= min && min <= 32767) && (-32768 <= max && max <= 32767)
          "std::int16_t"
        when (0 <= min && min <= 65535) && (0 <= max && max <= 65535)
          "std::uint16_t"
        else
          "int"
        end
      end

      def render_token_definitions
        context.yytokentype.map do |s_value, token_id, display_name|
          "static constexpr int #{token_constant_name(s_value)} = #{token_id};#{render_c_style_token_comment(display_name)}\n"
        end.join
      end

      def render_symbol_definitions
        context.yysymbol_kind_t.map do |s_value, sym_number, display_name|
          "static constexpr int #{sanitized_identifier(s_value)} = #{sym_number};#{render_c_style_token_comment(display_name)}\n"
        end.join
      end

      def render_user_actions(_grammar_file_path)
        action_rules.map do |rule|
          <<-CPP
    case #{rule.id + 1}: { // #{rule.as_comment}
#{indent(translated_rule_code(rule), 6)}
      break;
    }
          CPP
        end.join
      end
    end

    register(:cpp, Cpp)
  end
end
