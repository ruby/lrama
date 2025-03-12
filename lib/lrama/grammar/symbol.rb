# rbs_inline: enabled
# frozen_string_literal: true

# Symbol is both of nterm and term
# `number` is both for nterm and term
# `token_id` is tokentype for term, internal sequence number for nterm
#
# TODO: Add validation for ASCII code range for Token::Char

module Lrama
  class Grammar
    class Symbol
      attr_accessor :id #: Lexer::Token
      attr_accessor :alias_name #: String?
      attr_reader :number #: Integer
      attr_accessor :number_bitmap #: Bitmap::bitmap
      attr_accessor :tag #: Lexer::Token::Tag?
      attr_accessor :token_id #: Integer
      attr_accessor :nullable #: bool
      attr_accessor :precedence #: Precedence?
      attr_accessor :printer #: Printer?
      attr_accessor :destructor #: Destructor?
      attr_accessor :error_token #: ErrorToken
      attr_accessor :first_set #: Set[Grammar::Symbol]
      attr_accessor :first_set_bitmap #: Bitmap::bitmap
      attr_reader :term #: bool
      attr_writer :eof_symbol #: bool
      attr_writer :error_symbol #: bool
      attr_writer :undef_symbol #: bool
      attr_writer :accept_symbol #: bool

      # @rbs (id: Lexer::Token, term: bool, ?alias_name: String?, ?number: Integer?, ?tag: Lexer::Token?,
      #      ?token_id: Integer?, ?nullable: bool?, ?precedence: Precedence?, ?printer: Printer?) -> void
      def initialize(id:, term:, alias_name: nil, number: nil, tag: nil, token_id: nil, nullable: nil, precedence: nil, printer: nil, destructor: nil)
        @id = id
        @alias_name = alias_name
        @number = number
        @tag = tag
        @term = term
        @token_id = token_id
        @nullable = nullable
        @precedence = precedence
        @printer = printer
        @destructor = destructor
      end

      # @rbs (Integer) -> void
      def number=(number)
        @number = number
        @number_bitmap = Bitmap::from_array([number])
      end

      # @rbs () -> bool
      def term?
        term
      end

      # @rbs () -> bool
      def nterm?
        !term
      end

      # @rbs () -> bool
      def eof_symbol?
        !!@eof_symbol
      end

      # @rbs () -> bool
      def error_symbol?
        !!@error_symbol
      end

      # @rbs () -> bool
      def undef_symbol?
        !!@undef_symbol
      end

      # @rbs () -> bool
      def accept_symbol?
        !!@accept_symbol
      end

      # @rbs () -> String
      def display_name
        alias_name || id.s_value
      end

      # name for yysymbol_kind_t
      #
      # See: b4_symbol_kind_base
      # @type var name: String
      # @rbs () -> String
      def enum_name
        case
        when accept_symbol?
          name = "YYACCEPT"
        when eof_symbol?
          name = "YYEOF"
        when term? && id.is_a?(Lrama::Lexer::Token::Char)
          name = number.to_s + display_name
        when term? && id.is_a?(Lrama::Lexer::Token::Ident)
          name = id.s_value
        when nterm? && (id.s_value.include?("$") || id.s_value.include?("@"))
          name = number.to_s + id.s_value
        when nterm?
          name = id.s_value
        else
          raise "Unexpected #{self}"
        end

        "YYSYMBOL_" + name.gsub(/\W+/, "_")
      end

      # comment for yysymbol_kind_t
      #
      # @rbs () -> String?
      def comment
        case
        when accept_symbol?
          # YYSYMBOL_YYACCEPT
          id.s_value
        when eof_symbol?
          # YYEOF
          alias_name
        when (term? && 0 < token_id && token_id < 128)
          # YYSYMBOL_3_backslash_, YYSYMBOL_14_
          alias_name || id.s_value
        when id.s_value.include?("$") || id.s_value.include?("@")
          # YYSYMBOL_21_1
          id.s_value
        else
          # YYSYMBOL_keyword_class, YYSYMBOL_strings_1
          alias_name || id.s_value
        end
      end
    end
  end
end
