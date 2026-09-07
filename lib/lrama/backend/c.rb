# frozen_string_literal: true

require_relative "base"
require_relative "c/reference_translator"

module Lrama
  module Backend
    class C < Base
      def file_extension
        "c"
      end

      def template_file
        File.join(template_dir, "bison/yacc.c")
      end

      def header_template_file
        File.join(template_dir, "bison/yacc.h")
      end

      def translator
        @translator ||= ReferenceTranslator.new
      end

      def format_int_array(ary)
        last = ary.count - 1

        ary.each_with_index.each_slice(10).map do |slice|
          "  " + slice.map { |e, i| sprintf("%6d%s", e, (i == last) ? "" : ",") }.join
        end.join("\n")
      end

      def format_string_array(ary)
        result = ""
        tmp = " "

        ary.each do |s|
          replaced = s.gsub('\\', '\\\\\\\\').gsub('"', '\\"')
          if (tmp + replaced + " \"\",").length > 75
            result = "#{result}#{tmp}\n"
            tmp = "  \"#{replaced}\","
          else
            tmp = "#{tmp} \"#{replaced}\","
          end
        end

        result + tmp
      end

      def token_enums
        context.yytokentype.map do |s_value, token_id, display_name|
          s = sprintf("%s = %d%s", s_value, token_id, token_id == context.yymaxutok ? "" : ",")

          if display_name
            sprintf("    %-30s /* %s  */\n", s, display_name)
          else
            sprintf("    %s\n", s)
          end
        end.join
      end

      def symbol_enum
        last_sym_number = context.yysymbol_kind_t.last[1]
        context.yysymbol_kind_t.map do |s_value, sym_number, display_name|
          s = sprintf("%s = %d%s", s_value, sym_number, (sym_number == last_sym_number) ? "" : ",")

          if display_name
            sprintf("  %-40s /* %s  */\n", s, display_name)
          else
            sprintf("  %s\n", s)
          end
        end.join
      end

      def int_type_for(ary)
        min = ary.min
        max = ary.max

        case
        when (-127 <= min && min <= 127) && (-127 <= max && max <= 127)
          "yytype_int8"
        when (0 <= min && min <= 255) && (0 <= max && max <= 255)
          "yytype_uint8"
        when (-32767 <= min && min <= 32767) && (-32767 <= max && max <= 32767)
          "yytype_int16"
        when (0 <= min && min <= 65535) && (0 <= max && max <= 65535)
          "yytype_uint16"
        else
          "int"
        end
      end

      def render_symbol_actions_for_printer(grammar_file_path)
        render_symbol_actions(grammar_file_path, :printer)
      end

      def render_symbol_actions_for_destructor(grammar_file_path)
        render_symbol_actions(grammar_file_path, :destructor)
      end

      def render_symbol_actions_for_error_token(grammar_file_path)
        render_symbol_actions(grammar_file_path, :error_token)
      end

      def render_user_actions(grammar_file_path)
        action = context.states.rules.map do |rule|
          next unless rule.token_code

          code = rule.token_code
          spaces = " " * (code.column - 1)

          <<-STR
  case #{rule.id + 1}: /* #{rule.as_comment}  */
#line #{code.line} "#{grammar_file_path}"
#{spaces}{#{rule.translated_code(grammar, translator)}}
#line [@oline@] [@ofile@]
    break;

          STR
        end.join

        action + <<-STR

#line [@oline@] [@ofile@]
        STR
      end

      private

      def render_symbol_actions(grammar_file_path, action_type)
        grammar.symbols.map do |sym|
          action = sym.public_send(action_type)
          next unless action

          <<-STR
    case #{sym.enum_name}: /* #{sym.comment}  */
#line #{action.lineno} "#{grammar_file_path}"
         {#{action.translated_code(sym.tag)}}
#line [@oline@] [@ofile@]
        break;

          STR
        end.join
      end
    end

    register(:c, C)
  end
end
