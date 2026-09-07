# frozen_string_literal: true

require_relative "table"
require_relative "rust/reference_translator"

module Lrama
  module Backend
    class Rust < Table
      def file_extension
        "rs"
      end

      def template_file
        File.join(template_dir, "rust/parser.rs.erb")
      end

      def translator
        @translator ||= ReferenceTranslator.new
      end

      def format_int_array(ary)
        "&[#{ary.join(', ')}]"
      end

      def format_string_array(ary)
        "&[#{ary.map { |s| string_literal(s) }.join(', ')}]"
      end

      def int_type_for(ary)
        min = ary.min
        max = ary.max

        case
        when (-128 <= min && min <= 127) && (-128 <= max && max <= 127)
          "i8"
        when (0 <= min && min <= 255) && (0 <= max && max <= 255)
          "u8"
        when (-32768 <= min && min <= 32767) && (-32768 <= max && max <= 32767)
          "i16"
        when (0 <= min && min <= 65535) && (0 <= max && max <= 65535)
          "u16"
        else
          "i32"
        end
      end

      def render_token_definitions
        context.yytokentype.map do |s_value, token_id, display_name|
          "pub const #{token_constant_name(s_value)}: i32 = #{token_id};#{render_c_style_token_comment(display_name)}\n"
        end.join
      end

      def render_symbol_definitions
        context.yysymbol_kind_t.map do |s_value, sym_number, display_name|
          "const #{sanitized_identifier(s_value)}: i32 = #{sym_number};#{render_c_style_token_comment(display_name)}\n"
        end.join
      end

      def render_user_actions(_grammar_file_path)
        action_rules.map do |rule|
          <<-RUST
            #{rule.id + 1} => { // #{rule.as_comment}
#{indent(translated_rule_code(rule), 14)}
            }
          RUST
        end.join
      end
    end

    register(:rust, Rust)
  end
end
