RSpec.describe Lrama::Lexer do
  T = Lrama::Lexer::Token

  describe '#lex' do
    it "basic" do
      y = File.read(fixture_path("common/basic.y"))
      lexer = Lrama::Lexer.new(y)

      expect(lexer.prologue.first[1]).to eq(7)
      expect(lexer.prologue.map(&:first).join).to eq(<<~TEXT)
        // Prologue
      TEXT

      expect(lexer.bison_declarations.first[1]).to eq(10)
      expect(lexer.bison_declarations.map(&:first).join).to eq(<<~TEXT)

        %expect 0
        %define api.pure
        %define parse.error verbose

        %printer {
            print_int();
        } <int>
        %printer {
            print_token();
        } tNUMBER tSTRING

        %lex-param {struct lex_params *p}
        %parse-param {struct parse_params *p}

        %initial-action
        {
            initial_action_func(@$);
        };

        %union {
            int i;
            long l;
            char *str;
        }

        %token EOI 0 "EOI"
        %token <i> '\\\\'  "backslash"
        %token <i> '\\13' "escaped vertical tab"
        %token <i> keyword_class
        %token <i> keyword_class2
        %token <l> tNUMBER
        %token <str> tSTRING
        %token <i> keyword_end "end"
        %token tPLUS  "+"
        %token tMINUS "-"
        %token tEQ    "="
        %token tEQEQ  "=="

        %type <i> class /* comment for class */

        %nonassoc tEQEQ
        %left  tPLUS tMINUS '>'
        %right tEQ

      TEXT

      expect(lexer.grammar_rules.first[1]).to eq(56)
      expect(lexer.grammar_rules.map(&:first).join).to eq(<<~TEXT)

        program: class
               | '+' strings_1
               | '-' strings_2
               ;

        class : keyword_class tSTRING keyword_end %prec tPLUS
                  { code 1 }
              | keyword_class { code 2 } tSTRING '!' keyword_end { code 3 } %prec "="
              | keyword_class { code 4 } tSTRING '?' keyword_end { code 5 } %prec '>'
              ;

        strings_1: string_1
                 ;

        strings_2: string_1
                 | string_2
                 ;

        string_1: string
                ;

        string_2: string '+'
                ;

        string: tSTRING
              ;

      TEXT

      expect(lexer.epilogue.first[1]).to eq(85)
      expect(lexer.epilogue.map(&:first).join).to eq(<<~TEXT)

        // Epilogue
      TEXT

      expect(lexer.bison_declarations_tokens).to eq([
        T.new(T::P_expect, "%expect"),
        T.new(T::Number, 0),

        T.new(T::P_define, "%define"),
        T.new(T::Ident, "api.pure"),

        T.new(T::P_define, "%define"),
        T.new(T::Ident, "parse.error"),
        T.new(T::Ident, "verbose"),

        T.new(T::P_printer, "%printer"),
        T.new(T::User_code, "{\n    print_int();\n}"),
        T.new(T::Tag, "<int>"),

        T.new(T::P_printer, "%printer"),
        T.new(T::User_code, "{\n    print_token();\n}"),
        T.new(T::Ident, "tNUMBER"),
        T.new(T::Ident, "tSTRING"),

        T.new(T::P_lex_param, "%lex-param"),
        T.new(T::User_code, "{struct lex_params *p}"),

        T.new(T::P_parse_param, "%parse-param"),
        T.new(T::User_code, "{struct parse_params *p}"),

        T.new(T::P_initial_action, "%initial-action"),
        T.new(T::User_code, "{\n    initial_action_func(@$);\n}"),
        T.new(T::Semicolon, ";"),

        T.new(T::P_union, "%union"),
        T.new(T::User_code, "{\n    int i;\n    long l;\n    char *str;\n}"),

        T.new(T::P_token, "%token"),
        T.new(T::Ident, "EOI"),
        T.new(T::Number, 0),
        T.new(T::String, "\"EOI\""),

        T.new(T::P_token, "%token"),
        T.new(T::Tag, "<i>"),
        T.new(T::Char, "'\\\\'"),
        T.new(T::String, "\"backslash\""),

        T.new(T::P_token, "%token"),
        T.new(T::Tag, "<i>"),
        T.new(T::Char, "'\\13'"),
        T.new(T::String, "\"escaped vertical tab\""),

        T.new(T::P_token, "%token"),
        T.new(T::Tag, "<i>"),
        T.new(T::Ident, "keyword_class"),

        T.new(T::P_token, "%token"),
        T.new(T::Tag, "<i>"),
        T.new(T::Ident, "keyword_class2"),

        T.new(T::P_token, "%token"),
        T.new(T::Tag, "<l>"),
        T.new(T::Ident, "tNUMBER"),

        T.new(T::P_token, "%token"),
        T.new(T::Tag, "<str>"),
        T.new(T::Ident, "tSTRING"),

        T.new(T::P_token, "%token"),
        T.new(T::Tag, "<i>"),
        T.new(T::Ident, "keyword_end"),
        T.new(T::String, "\"end\""),

        T.new(T::P_token, "%token"),
        T.new(T::Ident, "tPLUS"),
        T.new(T::String, "\"+\""),

        T.new(T::P_token, "%token"),
        T.new(T::Ident, "tMINUS"),
        T.new(T::String, "\"-\""),

        T.new(T::P_token, "%token"),
        T.new(T::Ident, "tEQ"),
        T.new(T::String, "\"=\""),

        T.new(T::P_token, "%token"),
        T.new(T::Ident, "tEQEQ"),
        T.new(T::String, "\"==\""),

        T.new(T::P_type, "%type"),
        T.new(T::Tag, "<i>"),
        T.new(T::Ident, "class"),

        T.new(T::P_nonassoc, "%nonassoc"),
        T.new(T::Ident, "tEQEQ"),

        T.new(T::P_left, "%left"),
        T.new(T::Ident, "tPLUS"),
        T.new(T::Ident, "tMINUS"),
        T.new(T::Char, "'>'"),

        T.new(T::P_right, "%right"),
        T.new(T::Ident, "tEQ"),
      ])

      expect(lexer.grammar_rules_tokens).to eq([
        T.new(T::Ident, "program"),
        T.new(T::Colon, ":"),
        T.new(T::Ident, "class"),

        T.new(T::Bar, "|"),
        T.new(T::Char, "'+'"),
        T.new(T::Ident, "strings_1"),

        T.new(T::Bar, "|"),
        T.new(T::Char, "'-'"),
        T.new(T::Ident, "strings_2"),
        T.new(T::Semicolon, ";"),


        T.new(T::Ident, "class"),
        T.new(T::Colon, ":"),
        T.new(T::Ident, "keyword_class"),
        T.new(T::Ident, "tSTRING"),
        T.new(T::Ident, "keyword_end"),
        T.new(T::P_prec, "%prec"),
        T.new(T::Ident, "tPLUS"),
        T.new(T::User_code, "{ code 1 }"),

        T.new(T::Bar, "|"),
        T.new(T::Ident, "keyword_class"),
        T.new(T::User_code, "{ code 2 }"),
        T.new(T::Ident, "tSTRING"),
        T.new(T::Char, "'!'"),
        T.new(T::Ident, "keyword_end"),
        T.new(T::User_code, "{ code 3 }"),
        T.new(T::P_prec, "%prec"),
        T.new(T::String, "\"=\""),

        T.new(T::Bar, "|"),
        T.new(T::Ident, "keyword_class"),
        T.new(T::User_code, "{ code 4 }"),
        T.new(T::Ident, "tSTRING"),
        T.new(T::Char, "'?'"),
        T.new(T::Ident, "keyword_end"),
        T.new(T::User_code, "{ code 5 }"),
        T.new(T::P_prec, "%prec"),
        T.new(T::Char, "'>'"),
        T.new(T::Semicolon, ";"),


        T.new(T::Ident, "strings_1"),
        T.new(T::Colon, ":"),
        T.new(T::Ident, "string_1"),
        T.new(T::Semicolon, ";"),


        T.new(T::Ident, "strings_2"),
        T.new(T::Colon, ":"),
        T.new(T::Ident, "string_1"),
        T.new(T::Bar, "|"),

        T.new(T::Ident, "string_2"),
        T.new(T::Semicolon, ";"),


        T.new(T::Ident, "string_1"),
        T.new(T::Colon, ":"),
        T.new(T::Ident, "string"),
        T.new(T::Semicolon, ";"),


        T.new(T::Ident, "string_2"),
        T.new(T::Colon, ":"),
        T.new(T::Ident, "string"),
        T.new(T::Char, "'+'"),
        T.new(T::Semicolon, ";"),


        T.new(T::Ident, "string"),
        T.new(T::Colon, ":"),
        T.new(T::Ident, "tSTRING"),
        T.new(T::Semicolon, ";"),
      ])
    end

    it "nullable" do
      y = File.read(fixture_path("common/nullable.y"))
      lexer = Lrama::Lexer.new(y)

      expect(lexer.grammar_rules_tokens).to eq([
        T.new(T::Ident, "program"),
        T.new(T::Colon, ":"),
        T.new(T::Ident, "stmt"),
        T.new(T::Semicolon, ";"),

        T.new(T::Ident, "stmt"),
        T.new(T::Colon, ":"),
        T.new(T::Ident, "expr"),
        T.new(T::Ident, "opt_semicolon"),
        T.new(T::Bar, "|"),
        T.new(T::Ident, "opt_expr"),
        T.new(T::Ident, "opt_colon"),
        T.new(T::Bar, "|"),
        T.new(T::Semicolon, ";"),

        T.new(T::Ident, "expr"),
        T.new(T::Colon, ":"),
        T.new(T::Ident, "tNUMBER"),
        T.new(T::Semicolon, ";"),

        T.new(T::Ident, "opt_expr"),
        T.new(T::Colon, ":"),
        T.new(T::Bar, "|"),
        T.new(T::Ident, "expr"),
        T.new(T::Semicolon, ";"),

        T.new(T::Ident, "opt_semicolon"),
        T.new(T::Colon, ":"),
        T.new(T::Bar, "|"),
        T.new(T::Char, "';'"),
        T.new(T::Semicolon, ";"),

        T.new(T::Ident, "opt_colon"),
        T.new(T::Colon, ":"),
        T.new(T::Bar, "|"),
        T.new(T::Char, "'.'"),
        T.new(T::Semicolon, ";"),
      ])
    end

    it "user_code" do
      y = <<~INPUT
%{
// Prologue
%}

%union {
    int i;
}

%token EOI 0 "EOI"
%token tLAMBDA tARGS tBODY

%%

program: lambda ;

lambda: tLAMBDA
          { $<int>1 = 1; $<int>$ = 2; }
          { $<int>$ = 3; }
          { $<int>$ = 4; }
        tARGS
          { 5; }
        tBODY
          { $2; $3; $5; $7; $$ = 1; }
        ;
%%
      INPUT
      lexer = Lrama::Lexer.new(y)
      user_codes = lexer.grammar_rules_tokens.select do |t|
        t.type == T::User_code
      end

      expect(user_codes.map(&:references)).to eq([
        [
          [:dollar, 1, T.new(T::Tag, "<int>"), 2, 8],
          [:dollar, "$", T.new(T::Tag, "<int>"), 15, 21]
        ],
        [
          [:dollar, "$", T.new(T::Tag, "<int>"), 2, 8]
        ],
        [
          [:dollar, "$", T.new(T::Tag, "<int>"), 2, 8]
        ],
        [],
        [
          [:dollar, 2, nil, 2, 3],
          [:dollar, 3, nil, 6, 7],
          [:dollar, 5, nil, 10, 11],
          [:dollar, 7, nil, 14, 15],
          [:dollar, "$", nil, 18, 19]
        ],
      ])
    end

    describe "user codes" do
      it "parses comments correctly" do
        y = <<~INPUT
%{
// Prologue
%}

%union {
    int i;
}

%token EOI 0 "EOI"
%token tBODY

%%

program: stmt ;

stmt: tBODY
        {
          int i = 1; /* @ */
          int j = 1; /* $ */
          int k = 1; /* @1 */
          int l = 1; /* $$ */
          int m = 1; /* $2 */
        }
    ;
%%
        INPUT
        lexer = Lrama::Lexer.new(y)
        user_codes = lexer.grammar_rules_tokens.select do |t|
          t.type == T::User_code
        end

        expected = <<-CODE.chomp
{
          int i = 1; /* @ */
          int j = 1; /* $ */
          int k = 1; /* @1 */
          int l = 1; /* $$ */
          int m = 1; /* $2 */
        }
        CODE

        expect(user_codes.map(&:s_value)).to eq([expected])
      end
    end
  end
end
