# frozen_string_literal: true

require_relative "table"
require_relative "ruby/reference_translator"

module Lrama
  module Backend
    class Ruby < Table
      def file_extension
        "rb"
      end

      def template_file
        File.join(template_dir, "ruby/parser.rb.erb")
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

      def int_type_for(_ary)
        "Integer"
      end

      def render_token_definitions
        context.yytokentype.map do |s_value, token_id, display_name|
          "#{token_constant_name(s_value)} = #{token_id}#{render_token_comment(display_name)}\n"
        end.join
      end

      def render_symbol_definitions
        context.yysymbol_kind_t.map do |s_value, sym_number, display_name|
          "#{sanitized_identifier(s_value)} = #{sym_number}#{render_token_comment(display_name)}\n"
        end.join
      end

      def render_user_actions(_grammar_file_path)
        action_rules.map do |rule|
          <<-RUBY
    when #{rule.id + 1} # #{rule.as_comment}
#{indent(translated_rule_code(rule), 6)}
          RUBY
        end.join
      end
    end

    register(:ruby, Ruby)
  end
end
