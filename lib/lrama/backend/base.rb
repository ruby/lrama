# frozen_string_literal: true

module Lrama
  module Backend
    class Base
      attr_reader :context, :grammar, :options

      def initialize(context:, grammar:, options:)
        @context = context
        @grammar = grammar
        @options = options
      end

      def format_int_array(_ary)
        raise NotImplementedError
      end

      def format_string_array(_ary)
        raise NotImplementedError
      end

      def int_type_for(_ary)
        raise NotImplementedError
      end

      def token_enums
        raise NotImplementedError
      end

      def symbol_enum
        raise NotImplementedError
      end

      def translator
        raise NotImplementedError
      end

      def template_file
        raise NotImplementedError
      end

      def header_template_file
        nil
      end

      def file_extension
        raise NotImplementedError
      end

      def post_process(output_string)
        output_string
      end

      private

      def template_dir
        File.expand_path('../../../template', __dir__)
      end
    end
  end
end
