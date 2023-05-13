RSpec.describe Lrama::Lexer do
  T ||= Lrama::Lexer::Token

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
        T.new(type: T::P_expect, s_value: "%expect"),
        T.new(type: T::Number, s_value: 0),

        T.new(type: T::P_define, s_value: "%define"),
        T.new(type: T::Ident, s_value: "api.pure"),

        T.new(type: T::P_define, s_value: "%define"),
        T.new(type: T::Ident, s_value: "parse.error"),
        T.new(type: T::Ident, s_value: "verbose"),

        T.new(type: T::P_printer, s_value: "%printer"),
        T.new(type: T::User_code, s_value: "{\n    print_int();\n}"),
        T.new(type: T::Tag, s_value: "<int>"),

        T.new(type: T::P_printer, s_value: "%printer"),
        T.new(type: T::User_code, s_value: "{\n    print_token();\n}"),
        T.new(type: T::Ident, s_value: "tNUMBER"),
        T.new(type: T::Ident, s_value: "tSTRING"),

        T.new(type: T::P_lex_param, s_value: "%lex-param"),
        T.new(type: T::User_code, s_value: "{struct lex_params *p}"),

        T.new(type: T::P_parse_param, s_value: "%parse-param"),
        T.new(type: T::User_code, s_value: "{struct parse_params *p}"),

        T.new(type: T::P_initial_action, s_value: "%initial-action"),
        T.new(type: T::User_code, s_value: "{\n    initial_action_func(@$);\n}"),
        T.new(type: T::Semicolon, s_value: ";"),

        T.new(type: T::P_union, s_value: "%union"),
        T.new(type: T::User_code, s_value: "{\n    int i;\n    long l;\n    char *str;\n}"),

        T.new(type: T::P_token, s_value: "%token"),
        T.new(type: T::Ident, s_value: "EOI"),
        T.new(type: T::Number, s_value: 0),
        T.new(type: T::String, s_value: "\"EOI\""),

        T.new(type: T::P_token, s_value: "%token"),
        T.new(type: T::Tag, s_value: "<i>"),
        T.new(type: T::Char, s_value: "'\\\\'"),
        T.new(type: T::String, s_value: "\"backslash\""),

        T.new(type: T::P_token, s_value: "%token"),
        T.new(type: T::Tag, s_value: "<i>"),
        T.new(type: T::Char, s_value: "'\\13'"),
        T.new(type: T::String, s_value: "\"escaped vertical tab\""),

        T.new(type: T::P_token, s_value: "%token"),
        T.new(type: T::Tag, s_value: "<i>"),
        T.new(type: T::Ident, s_value: "keyword_class"),

        T.new(type: T::P_token, s_value: "%token"),
        T.new(type: T::Tag, s_value: "<i>"),
        T.new(type: T::Ident, s_value: "keyword_class2"),

        T.new(type: T::P_token, s_value: "%token"),
        T.new(type: T::Tag, s_value: "<l>"),
        T.new(type: T::Ident, s_value: "tNUMBER"),

        T.new(type: T::P_token, s_value: "%token"),
        T.new(type: T::Tag, s_value: "<str>"),
        T.new(type: T::Ident, s_value: "tSTRING"),

        T.new(type: T::P_token, s_value: "%token"),
        T.new(type: T::Tag, s_value: "<i>"),
        T.new(type: T::Ident, s_value: "keyword_end"),
        T.new(type: T::String, s_value: "\"end\""),

        T.new(type: T::P_token, s_value: "%token"),
        T.new(type: T::Ident, s_value: "tPLUS"),
        T.new(type: T::String, s_value: "\"+\""),

        T.new(type: T::P_token, s_value: "%token"),
        T.new(type: T::Ident, s_value: "tMINUS"),
        T.new(type: T::String, s_value: "\"-\""),

        T.new(type: T::P_token, s_value: "%token"),
        T.new(type: T::Ident, s_value: "tEQ"),
        T.new(type: T::String, s_value: "\"=\""),

        T.new(type: T::P_token, s_value: "%token"),
        T.new(type: T::Ident, s_value: "tEQEQ"),
        T.new(type: T::String, s_value: "\"==\""),

        T.new(type: T::P_type, s_value: "%type"),
        T.new(type: T::Tag, s_value: "<i>"),
        T.new(type: T::Ident, s_value: "class"),

        T.new(type: T::P_nonassoc, s_value: "%nonassoc"),
        T.new(type: T::Ident, s_value: "tEQEQ"),

        T.new(type: T::P_left, s_value: "%left"),
        T.new(type: T::Ident, s_value: "tPLUS"),
        T.new(type: T::Ident, s_value: "tMINUS"),
        T.new(type: T::Char, s_value: "'>'"),

        T.new(type: T::P_right, s_value: "%right"),
        T.new(type: T::Ident, s_value: "tEQ"),
      ])

      expect(lexer.grammar_rules_tokens).to eq([
        T.new(type: T::Ident_Colon, s_value: "program"),
        T.new(type: T::Ident, s_value: "class"),

        T.new(type: T::Bar, s_value: "|"),
        T.new(type: T::Char, s_value: "'+'"),
        T.new(type: T::Ident, s_value: "strings_1"),

        T.new(type: T::Bar, s_value: "|"),
        T.new(type: T::Char, s_value: "'-'"),
        T.new(type: T::Ident, s_value: "strings_2"),
        T.new(type: T::Semicolon, s_value: ";"),


        T.new(type: T::Ident_Colon, s_value: "class"),
        T.new(type: T::Ident, s_value: "keyword_class"),
        T.new(type: T::Ident, s_value: "tSTRING"),
        T.new(type: T::Ident, s_value: "keyword_end"),
        T.new(type: T::P_prec, s_value: "%prec"),
        T.new(type: T::Ident, s_value: "tPLUS"),
        T.new(type: T::User_code, s_value: "{ code 1 }"),

        T.new(type: T::Bar, s_value: "|"),
        T.new(type: T::Ident, s_value: "keyword_class"),
        T.new(type: T::User_code, s_value: "{ code 2 }"),
        T.new(type: T::Ident, s_value: "tSTRING"),
        T.new(type: T::Char, s_value: "'!'"),
        T.new(type: T::Ident, s_value: "keyword_end"),
        T.new(type: T::User_code, s_value: "{ code 3 }"),
        T.new(type: T::P_prec, s_value: "%prec"),
        T.new(type: T::String, s_value: "\"=\""),

        T.new(type: T::Bar, s_value: "|"),
        T.new(type: T::Ident, s_value: "keyword_class"),
        T.new(type: T::User_code, s_value: "{ code 4 }"),
        T.new(type: T::Ident, s_value: "tSTRING"),
        T.new(type: T::Char, s_value: "'?'"),
        T.new(type: T::Ident, s_value: "keyword_end"),
        T.new(type: T::User_code, s_value: "{ code 5 }"),
        T.new(type: T::P_prec, s_value: "%prec"),
        T.new(type: T::Char, s_value: "'>'"),
        T.new(type: T::Semicolon, s_value: ";"),


        T.new(type: T::Ident_Colon, s_value: "strings_1"),
        T.new(type: T::Ident, s_value: "string_1"),
        T.new(type: T::Semicolon, s_value: ";"),


        T.new(type: T::Ident_Colon, s_value: "strings_2"),
        T.new(type: T::Ident, s_value: "string_1"),
        T.new(type: T::Bar, s_value: "|"),

        T.new(type: T::Ident, s_value: "string_2"),
        T.new(type: T::Semicolon, s_value: ";"),


        T.new(type: T::Ident_Colon, s_value: "string_1"),
        T.new(type: T::Ident, s_value: "string"),
        T.new(type: T::Semicolon, s_value: ";"),


        T.new(type: T::Ident_Colon, s_value: "string_2"),
        T.new(type: T::Ident, s_value: "string"),
        T.new(type: T::Char, s_value: "'+'"),
        T.new(type: T::Semicolon, s_value: ";"),


        T.new(type: T::Ident_Colon, s_value: "string"),
        T.new(type: T::Ident, s_value: "tSTRING"),
        T.new(type: T::Semicolon, s_value: ";"),
      ])
    end

    it "nullable" do
      y = File.read(fixture_path("common/nullable.y"))
      lexer = Lrama::Lexer.new(y)

      expect(lexer.grammar_rules_tokens).to eq([
        T.new(type: T::Ident_Colon, s_value: "program"),
        T.new(type: T::Ident, s_value: "stmt"),
        T.new(type: T::Semicolon, s_value: ";"),

        T.new(type: T::Ident_Colon, s_value: "stmt"),
        T.new(type: T::Ident, s_value: "expr"),
        T.new(type: T::Ident, s_value: "opt_semicolon"),
        T.new(type: T::Bar, s_value: "|"),
        T.new(type: T::Ident, s_value: "opt_expr"),
        T.new(type: T::Ident, s_value: "opt_colon"),
        T.new(type: T::Bar, s_value: "|"),
        T.new(type: T::Semicolon, s_value: ";"),

        T.new(type: T::Ident_Colon, s_value: "expr"),
        T.new(type: T::Ident, s_value: "tNUMBER"),
        T.new(type: T::Semicolon, s_value: ";"),

        T.new(type: T::Ident_Colon, s_value: "opt_expr"),
        T.new(type: T::Bar, s_value: "|"),
        T.new(type: T::Ident, s_value: "expr"),
        T.new(type: T::Semicolon, s_value: ";"),

        T.new(type: T::Ident_Colon, s_value: "opt_semicolon"),
        T.new(type: T::Bar, s_value: "|"),
        T.new(type: T::Char, s_value: "';'"),
        T.new(type: T::Semicolon, s_value: ";"),

        T.new(type: T::Ident_Colon, s_value: "opt_colon"),
        T.new(type: T::Bar, s_value: "|"),
        T.new(type: T::Char, s_value: "'.'"),
        T.new(type: T::Semicolon, s_value: ";"),
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
          [:dollar, 1, T.new(type: T::Tag, s_value: "<int>"), 2, 8],
          [:dollar, "$", T.new(type: T::Tag, s_value: "<int>"), 15, 21]
        ],
        [
          [:dollar, "$", T.new(type: T::Tag, s_value: "<int>"), 2, 8]
        ],
        [
          [:dollar, "$", T.new(type: T::Tag, s_value: "<int>"), 2, 8]
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
