RSpec.describe Lrama::Parser do
  T = Lrama::Lexer::Token
  Type = Lrama::Type
  Sym = Lrama::Symbol
  Precedence = Lrama::Precedence
  Rule = Lrama::Rule
  Printer = Lrama::Printer
  Code = Lrama::Code

  let(:header) do
    <<~HEADER
%{
// Prologue
%}

%union {
    int i;
    long l;
    char *str;
}

%token EOI 0 "EOI"
%token <i> keyword_class
%token <l> tNUMBER
%token <str> tSTRING
%token <i> keyword_end "end"
%token tPLUS  "+"
%token tMINUS "-"
%token tEQ    "="
%token tEQEQ  "=="

%type <i> class /* comment for class */

%nonassoc tEQEQ
%left  tPLUS tMINUS
%right tEQ

    HEADER
  end

  describe '#parse' do
    it "basic" do
      y = File.read(fixture_path("common/basic.y"))
      grammar = Lrama::Parser.new(y).parse

      expect(grammar.union.code.s_value).to eq(<<~CODE.chomp)
        {
            int i;
            long l;
            char *str;
        }
      CODE

      expect(grammar.expect).to eq(0)
      expect(grammar.printers).to eq([
        Printer.new(
          [T.new(T::Tag, "<int>")],
          Code.new(:printer, T.new(T::User_code, "{\n    print_int();\n}")),
          15
        ),
        Printer.new(
          [T.new(T::Ident, "tNUMBER"), T.new(T::Ident, "tSTRING")],
          Code.new(:printer, T.new(T::User_code, "{\n    print_token();\n}")),
          18
        ),
      ])
      expect(grammar.lex_param).to eq("{struct lex_params *p}")
      expect(grammar.parse_param).to eq("{struct parse_params *p}")
      expect(grammar.initial_action).to eq(Code.new(:initial_action, T.new(T::User_code, "{\n    initial_action_func(@$);\n}")))
      expect(grammar.symbols.sort_by(&:number)).to eq([
        Sym.new(T.new(T::Ident, "EOI"),            "\"EOI\"",                  0,                    nil, true,   0, false,                          nil, nil),
        Sym.new(T.new(T::Ident, "YYerror"),        "error",                    1,                    nil, true, 256, false,                          nil, nil),
        Sym.new(T.new(T::Ident, "YYUNDEF"),        "\"invalid token\"",        2,                    nil, true, 257, false,                          nil, nil),
        Sym.new(T.new(T::Char,  "'\\\\'"),         "\"backslash\"",            3,   T.new(T::Tag, "<i>"), true,  92, false,                          nil, nil),
        Sym.new(T.new(T::Char,  "'\\13'"),         "\"escaped vertical tab\"", 4,   T.new(T::Tag, "<i>"), true,  11, false,                          nil, nil),
        Sym.new(T.new(T::Ident, "keyword_class"),  nil,                        5,   T.new(T::Tag, "<i>"), true, 258, false,                          nil, nil),
        Sym.new(T.new(T::Ident, "keyword_class2"), nil,                        6,   T.new(T::Tag, "<i>"), true, 259, false,                          nil, nil),
        Sym.new(T.new(T::Ident, "tNUMBER"),        nil,                        7,   T.new(T::Tag, "<l>"), true, 260, false,                          nil, grammar.printers[1]),
        Sym.new(T.new(T::Ident, "tSTRING"),        nil,                        8, T.new(T::Tag, "<str>"), true, 261, false,                          nil, grammar.printers[1]),
        Sym.new(T.new(T::Ident, "keyword_end"),    "\"end\"",                  9,   T.new(T::Tag, "<i>"), true, 262, false,                          nil, nil),
        Sym.new(T.new(T::Ident, "tPLUS"),          "\"+\"",                   10,                    nil, true, 263, false,     Precedence.new(:left, 1), nil),
        Sym.new(T.new(T::Ident, "tMINUS"),         "\"-\"",                   11,                    nil, true, 264, false,     Precedence.new(:left, 1), nil),
        Sym.new(T.new(T::Ident, "tEQ"),            "\"=\"",                   12,                    nil, true, 265, false,    Precedence.new(:right, 2), nil),
        Sym.new(T.new(T::Ident, "tEQEQ"),          "\"==\"",                  13,                    nil, true, 266, false, Precedence.new(:nonassoc, 0), nil),
        Sym.new(T.new(T::Char,  "'>'"),            nil,                       14,                    nil, true,  62, false,     Precedence.new(:left, 1), nil),
        Sym.new(T.new(T::Char,  "'+'"),            nil,                       15,                    nil, true,  43, false,                          nil, nil),
        Sym.new(T.new(T::Char,  "'-'"),            nil,                       16,                    nil, true,  45, false,                          nil, nil),
        Sym.new(T.new(T::Char,  "'!'"),            nil,                       17,                    nil, true,  33, false,                          nil, nil),
        Sym.new(T.new(T::Char,  "'?'"),            nil,                       18,                    nil, true,  63, false,                          nil, nil),

        Sym.new(T.new(T::Ident, "$accept"),   nil, 19,                  nil, false,  0, false, nil, nil),
        Sym.new(T.new(T::Ident, "program"),   nil, 20,                  nil, false,  1, false, nil, nil),
        Sym.new(T.new(T::Ident, "class"),     nil, 21, T.new(T::Tag, "<i>"), false,  2, false, nil, nil),
        Sym.new(T.new(T::Ident, "$@1"),       nil, 22,                  nil, false,  3,  true, nil, nil),
        Sym.new(T.new(T::Ident, "$@2"),       nil, 23,                  nil, false,  4,  true, nil, nil),
        Sym.new(T.new(T::Ident, "$@3"),       nil, 24,                  nil, false,  5,  true, nil, nil),
        Sym.new(T.new(T::Ident, "$@4"),       nil, 25,                  nil, false,  6,  true, nil, nil),
        Sym.new(T.new(T::Ident, "strings_1"), nil, 26,                  nil, false,  7, false, nil, nil),
        Sym.new(T.new(T::Ident, "strings_2"), nil, 27,                  nil, false,  8, false, nil, nil),
        Sym.new(T.new(T::Ident, "string_1"),  nil, 28,                  nil, false,  9, false, nil, nil),
        Sym.new(T.new(T::Ident, "string_2"),  nil, 29,                  nil, false, 10, false, nil, nil),
        Sym.new(T.new(T::Ident, "string"),    nil, 30,                  nil, false, 11, false, nil, nil),
      ])
      expect(grammar.types).to eq([Type.new(T.new(T::Ident, "class"), T.new(T::Tag, "<i>"))])
      expect(grammar._rules).to eq([
        [
          T.new(T::Ident, "program"),
          [
            T.new(T::Ident, "class"),
          ],
          57,
        ],
        [
          T.new(T::Ident, "program"),
          [
            T.new(T::Char, "'+'"),
            T.new(T::Ident, "strings_1"),
          ],
          58,
        ],
        [
          T.new(T::Ident, "program"),
          [
            T.new(T::Char, "'-'"),
            T.new(T::Ident, "strings_2"),
          ],
          59,
        ],
        [
          T.new(T::Ident, "class"),
          [
            T.new(T::Ident, "keyword_class"),
            T.new(T::Ident, "tSTRING"),
            T.new(T::Ident, "keyword_end"),
            grammar.find_symbol_by_s_value!("tPLUS"),
            T.new(T::User_code, "{ code 1 }"),
          ],
          62,
        ],
        [
          T.new(T::Ident, "class"),
          [
            T.new(T::Ident, "keyword_class"),
            T.new(T::User_code, "{ code 2 }"),
            T.new(T::Ident, "tSTRING"),
            T.new(T::Char, "'!'"),
            T.new(T::Ident, "keyword_end"),
            T.new(T::User_code, "{ code 3 }"),
            grammar.find_symbol_by_s_value!("tEQ"),
          ],
          64,
        ],
        [
          T.new(T::Ident, "class"),
          [
            T.new(T::Ident, "keyword_class"),
            T.new(T::User_code, "{ code 4 }"),
            T.new(T::Ident, "tSTRING"),
            T.new(T::Char, "'?'"),
            T.new(T::Ident, "keyword_end"),
            T.new(T::User_code, "{ code 5 }"),
            grammar.find_symbol_by_s_value!("'>'"),
          ],
          65,
        ],
        [
          T.new(T::Ident, "strings_1"),
          [
            T.new(T::Ident, "string_1"),
          ],
          68,
        ],
        [
          T.new(T::Ident, "strings_2"),
          [
            T.new(T::Ident, "string_1"),
          ],
          71,
        ],
        [
          T.new(T::Ident, "strings_2"),
          [
            T.new(T::Ident, "string_2"),
          ],
          72,
        ],
        [
          T.new(T::Ident, "string_1"),
          [
            T.new(T::Ident, "string"),
          ],
          75,
        ],
        [
          T.new(T::Ident, "string_2"),
          [
            T.new(T::Ident, "string"),
            T.new(T::Char, "'+'"),
          ],
          78,
        ],
        [
          T.new(T::Ident, "string"),
          [
            T.new(T::Ident, "tSTRING")
          ],
          81,
        ],
      ])
      expect(grammar.rules).to eq([
        Rule.new(
          0,
          grammar.find_symbol_by_s_value!("$accept"),
          [
            grammar.find_symbol_by_s_value!("program"),
            grammar.find_symbol_by_s_value!("EOI"),
          ],
          nil,
          false,
          grammar.find_symbol_by_s_value!("EOI"),
          57,
        ),
        Rule.new(
          1,
          grammar.find_symbol_by_s_value!("program"),
          [
            grammar.find_symbol_by_s_value!("class"),
          ],
          nil,
          false,
          nil,
          57,
        ),
        Rule.new(
          2,
          grammar.find_symbol_by_s_value!("program"),
          [
            grammar.find_symbol_by_s_value!("'+'"),
            grammar.find_symbol_by_s_value!("strings_1"),
          ],
          nil,
          false,
          grammar.find_symbol_by_s_value!("'+'"),
          58,
        ),
        Rule.new(
          3,
          grammar.find_symbol_by_s_value!("program"),
          [
            grammar.find_symbol_by_s_value!("'-'"),
            grammar.find_symbol_by_s_value!("strings_2"),
          ],
          nil,
          false,
          grammar.find_symbol_by_s_value!("'-'"),
          59,
        ),
        Rule.new(
          4,
          grammar.find_symbol_by_s_value!("class"),
          [
            grammar.find_symbol_by_s_value!("keyword_class"),
            grammar.find_symbol_by_s_value!("tSTRING"),
            grammar.find_symbol_by_s_value!("keyword_end"),
          ],
          Code.new(:user_code, T.new(T::User_code, "{ code 1 }")),
          false,
          grammar.find_symbol_by_s_value!("tPLUS"),
          62,
        ),
        Rule.new(
          5,
          grammar.find_symbol_by_s_value!("$@1"),
          [],
          Code.new(:user_code, T.new(T::User_code, "{ code 2 }")),
          true,
          nil,
          64,
        ),
        Rule.new(
          6,
          grammar.find_symbol_by_s_value!("$@2"),
          [],
          Code.new(:user_code, T.new(T::User_code, "{ code 3 }")),
          true,
          nil,
          64,
        ),
        Rule.new(
          7,
          grammar.find_symbol_by_s_value!("class"),
          [
            grammar.find_symbol_by_s_value!("keyword_class"),
            grammar.find_symbol_by_s_value!("$@1"),
            grammar.find_symbol_by_s_value!("tSTRING"),
            grammar.find_symbol_by_s_value!("'!'"),
            grammar.find_symbol_by_s_value!("keyword_end"),
            grammar.find_symbol_by_s_value!("$@2"),
          ],
          nil,
          false,
          grammar.find_symbol_by_s_value!("tEQ"),
          64,
        ),
        Rule.new(
          8,
          grammar.find_symbol_by_s_value!("$@3"),
          [],
          Code.new(:user_code, T.new(T::User_code, "{ code 4 }")),
          true,
          nil,
          65,
        ),
        Rule.new(
          9,
          grammar.find_symbol_by_s_value!("$@4"),
          [],
          Code.new(:user_code, T.new(T::User_code, "{ code 5 }")),
          true,
          nil,
          65,
        ),
        Rule.new(
          10,
          grammar.find_symbol_by_s_value!("class"),
          [
            grammar.find_symbol_by_s_value!("keyword_class"),
            grammar.find_symbol_by_s_value!("$@3"),
            grammar.find_symbol_by_s_value!("tSTRING"),
            grammar.find_symbol_by_s_value!("'?'"),
            grammar.find_symbol_by_s_value!("keyword_end"),
            grammar.find_symbol_by_s_value!("$@4"),
          ],
          nil,
          false,
          grammar.find_symbol_by_s_value!("'>'"),
          65,
        ),
        Rule.new(
          11,
          grammar.find_symbol_by_s_value!("strings_1"),
          [
            grammar.find_symbol_by_s_value!("string_1"),
          ],
          nil,
          false,
          nil,
          68,
        ),
        Rule.new(
          12,
          grammar.find_symbol_by_s_value!("strings_2"),
          [
            grammar.find_symbol_by_s_value!("string_1"),
          ],
          nil,
          false,
          nil,
          71,
        ),
        Rule.new(
          13,
          grammar.find_symbol_by_s_value!("strings_2"),
          [
            grammar.find_symbol_by_s_value!("string_2"),
          ],
          nil,
          false,
          nil,
          72,
        ),
        Rule.new(
          14,
          grammar.find_symbol_by_s_value!("string_1"),
          [
            grammar.find_symbol_by_s_value!("string"),
          ],
          nil,
          false,
          nil,
          75,
        ),
        Rule.new(
          15,
          grammar.find_symbol_by_s_value!("string_2"),
          [
            grammar.find_symbol_by_s_value!("string"),
            grammar.find_symbol_by_s_value!("'+'"),
          ],
          nil,
          false,
          grammar.find_symbol_by_s_value!("'+'"),
          78,
        ),
        Rule.new(
          16,
          grammar.find_symbol_by_s_value!("string"),
          [
            grammar.find_symbol_by_s_value!("tSTRING"),
          ],
          nil,
          false,
          grammar.find_symbol_by_s_value!("tSTRING"),
          81,
        ),
      ])
    end

    it "nullable" do
      y = File.read(fixture_path("common/nullable.y"))
      grammar = Lrama::Parser.new(y).parse

      expect(grammar.nterms.sort_by(&:number)).to eq([
        Sym.new(T.new(T::Ident, "$accept"), nil, 6, nil, false, 0, false),
        Sym.new(T.new(T::Ident, "program"), nil, 7, nil, false, 1, true),
        Sym.new(T.new(T::Ident, "stmt"), nil, 8, nil, false, 2, true),
        Sym.new(T.new(T::Ident, "expr"), nil, 9, nil, false, 3, false),
        Sym.new(T.new(T::Ident, "opt_expr"), nil, 10, nil, false, 4, true),
        Sym.new(T.new(T::Ident, "opt_semicolon"), nil, 11, nil, false, 5, true),
        Sym.new(T.new(T::Ident, "opt_colon"), nil, 12, nil, false, 6, true),
      ])
      expect(grammar.rules).to eq([
        Rule.new(
          0,
          grammar.find_symbol_by_s_value!("$accept"),
          [
            grammar.find_symbol_by_s_value!("program"),
            grammar.find_symbol_by_s_value!("YYEOF"),
          ],
          nil,
          false,
          grammar.find_symbol_by_s_value!("YYEOF"),
          15,
        ),
        Rule.new(
          1,
          grammar.find_symbol_by_s_value!("program"),
          [
            grammar.find_symbol_by_s_value!("stmt"),
          ],
          nil,
          true,
          nil,
          15,
        ),
        Rule.new(
          2,
          grammar.find_symbol_by_s_value!("stmt"),
          [
            grammar.find_symbol_by_s_value!("expr"),
            grammar.find_symbol_by_s_value!("opt_semicolon"),
          ],
          nil,
          false,
          nil,
          17,
        ),
        Rule.new(
          3,
          grammar.find_symbol_by_s_value!("stmt"),
          [
            grammar.find_symbol_by_s_value!("opt_expr"),
            grammar.find_symbol_by_s_value!("opt_colon"),
          ],
          nil,
          true,
          nil,
          18,
        ),
        Rule.new(
          4,
          grammar.find_symbol_by_s_value!("stmt"),
          [],
          nil,
          true,
          nil,
          19,
        ),
        Rule.new(
          5,
          grammar.find_symbol_by_s_value!("expr"),
          [
            grammar.find_symbol_by_s_value!("tNUMBER"),
          ],
          nil,
          false,
          grammar.find_symbol_by_s_value!("tNUMBER"),
          22,
        ),
        Rule.new(
          6,
          grammar.find_symbol_by_s_value!("opt_expr"),
          [],
          nil,
          true,
          nil,
          24,
        ),
        Rule.new(
          7,
          grammar.find_symbol_by_s_value!("opt_expr"),
          [
            grammar.find_symbol_by_s_value!("expr"),
          ],
          nil,
          false,
          nil,
          25,
        ),
        Rule.new(
          8,
          grammar.find_symbol_by_s_value!("opt_semicolon"),
          [],
          nil,
          true,
          nil,
          28,
        ),
        Rule.new(
          9,
          grammar.find_symbol_by_s_value!("opt_semicolon"),
          [
            grammar.find_symbol_by_s_value!("';'"),
          ],
          nil,
          false,
          grammar.find_symbol_by_s_value!("';'"),
          29,
        ),
        Rule.new(
          10,
          grammar.find_symbol_by_s_value!("opt_colon"),
          [],
          nil,
          true,
          nil,
          32,
        ),
        Rule.new(
          11,
          grammar.find_symbol_by_s_value!("opt_colon"),
          [
            grammar.find_symbol_by_s_value!("'.'"),
          ],
          nil,
          false,
          grammar.find_symbol_by_s_value!("'.'"),
          33,
        ),
      ])
    end

    it "error token" do
        y = header + <<~INPUT
%%

program: class ;

class : keyword_class tSTRING keyword_end { code 1 }
      | error
      ;

%%

        INPUT
        grammar = Lrama::Parser.new(y).parse

        expect(grammar.terms.sort_by(&:number)).to eq([
          Sym.new(T.new(T::Ident, "EOI"),            "\"EOI\"",           0,                    nil, true,   0, false, nil),
          Sym.new(T.new(T::Ident, "YYerror"),        "error",             1,                    nil, true, 256, false, nil),
          Sym.new(T.new(T::Ident, "YYUNDEF"),        "\"invalid token\"", 2,                    nil, true, 257, false, nil),
          Sym.new(T.new(T::Ident, "keyword_class"),  nil,                 3,   T.new(T::Tag, "<i>"), true, 258, false, nil),
          Sym.new(T.new(T::Ident, "tNUMBER"),        nil,                 4,   T.new(T::Tag, "<l>"), true, 259, false, nil),
          Sym.new(T.new(T::Ident, "tSTRING"),        nil,                 5, T.new(T::Tag, "<str>"), true, 260, false, nil),
          Sym.new(T.new(T::Ident, "keyword_end"),    "\"end\"",           6,   T.new(T::Tag, "<i>"), true, 261, false, nil),
          Sym.new(T.new(T::Ident, "tPLUS"),          "\"+\"",             7,                    nil, true, 262, false, Precedence.new(:left, 1)),
          Sym.new(T.new(T::Ident, "tMINUS"),         "\"-\"",             8,                    nil, true, 263, false, Precedence.new(:left, 1)),
          Sym.new(T.new(T::Ident, "tEQ"),            "\"=\"",             9,                    nil, true, 264, false, Precedence.new(:right, 2)),
          Sym.new(T.new(T::Ident, "tEQEQ"),          "\"==\"",           10,                    nil, true, 265, false, Precedence.new(:nonassoc, 0)),
        ])
        expect(grammar._rules).to eq([
          [
            T.new(T::Ident, "program"),
            [
              T.new(T::Ident, "class")
            ],
            29,
          ],
          [
            T.new(T::Ident, "class"),
            [
              T.new(T::Ident, "keyword_class"),
              T.new(T::Ident, "tSTRING"),
              T.new(T::Ident, "keyword_end"),
              T.new(T::User_code, "{ code 1 }"),
            ],
            31,
          ],
          [
            T.new(T::Ident, "class"),
            [
              T.new(T::Ident, "error")
            ],
            32,
          ],
        ])
    end

    it "action in the middle of RHS " do
        y = header + <<~INPUT
%%

program: class ;

class : keyword_class { code 1 } tSTRING { code 2 } keyword_end { code 3 }
      | keyword_class tSTRING keyword_end { code 4 }
      ;

%%

        INPUT
        grammar = Lrama::Parser.new(y).parse

        expect(grammar.nterms.sort_by(&:number)).to eq([
          Sym.new(T.new(T::Ident, "$accept"), nil, 11,                  nil, false, 0, false),
          Sym.new(T.new(T::Ident, "program"), nil, 12,                  nil, false, 1, false),
          Sym.new(T.new(T::Ident, "class"),   nil, 13, T.new(T::Tag, "<i>"), false, 2, false),
          Sym.new(T.new(T::Ident, "$@1"),     nil, 14,                  nil, false, 3, true),
          Sym.new(T.new(T::Ident, "$@2"),     nil, 15,                  nil, false, 4, true),
        ])
        expect(grammar.rules).to eq([
          Rule.new(
            0,
            grammar.find_symbol_by_s_value!("$accept"),
            [
              grammar.find_symbol_by_s_value!("program"),
              grammar.find_symbol_by_s_value!("EOI"),
            ],
            nil,
            false,
            grammar.find_symbol_by_s_value!("EOI"),
            29,
          ),
          Rule.new(
            1,
            grammar.find_symbol_by_s_value!("program"),
            [
              grammar.find_symbol_by_s_value!("class"),
            ],
            nil,
            false,
            nil,
            29,
          ),
          Rule.new(
            2,
            grammar.find_symbol_by_s_value!("$@1"),
            [],
            Code.new(:user_code, T.new(T::User_code, "{ code 1 }")),
            true,
            nil,
            31,
          ),
          Rule.new(
            3,
            grammar.find_symbol_by_s_value!("$@2"),
            [],
            Code.new(:user_code, T.new(T::User_code, "{ code 2 }")),
            true,
            nil,
            31,
          ),
          Rule.new(
            4,
            grammar.find_symbol_by_s_value!("class"),
            [
              grammar.find_symbol_by_s_value!("keyword_class"),
              grammar.find_symbol_by_s_value!("$@1"),
              grammar.find_symbol_by_s_value!("tSTRING"),
              grammar.find_symbol_by_s_value!("$@2"),
              grammar.find_symbol_by_s_value!("keyword_end"),
            ],
            Code.new(:user_code, T.new(T::User_code, "{ code 3 }")),
            false,
            grammar.find_symbol_by_s_value!("keyword_end"),
            31,
          ),
          Rule.new(
            5,
            grammar.find_symbol_by_s_value!("class"),
            [
              grammar.find_symbol_by_s_value!("keyword_class"),
              grammar.find_symbol_by_s_value!("tSTRING"),
              grammar.find_symbol_by_s_value!("keyword_end"),
            ],
            Code.new(:user_code, T.new(T::User_code, "{ code 4 }")),
            false,
            grammar.find_symbol_by_s_value!("keyword_end"),
            32,
          ),
        ])
    end

    describe "invalid_prec" do
      it do
        y = header + <<~INPUT
%%

program: class ;

class : keyword_class tSTRING %prec tPLUS keyword_end { code 1 }
      ;

%%

        INPUT
        parser = Lrama::Parser.new(y)

        expect { parser.parse }.to raise_error("Ident after %prec")
      end

      it do
        y = header + <<~INPUT
%%

program: class ;

class : keyword_class { code 2 } tSTRING %prec "=" '!' keyword_end { code 3 }
      ;

%%

        INPUT
        parser = Lrama::Parser.new(y)

        expect { parser.parse }.to raise_error("Char after %prec")
      end

      it do
        y = header + <<~INPUT
%%

program: class ;

class : keyword_class { code 4 } tSTRING '?' keyword_end %prec tEQ { code 5 } { code 6 }
      ;

%%

        INPUT
        parser = Lrama::Parser.new(y)

        expect { parser.parse }.to raise_error("Multiple User_code after %prec")
      end
    end

    describe "\" in user code" do
      it do
        y = header + <<~INPUT
%%

program: class ;

class : keyword_class
        {
            func("}");
        }
      ;

%%
        INPUT
        grammar = Lrama::Parser.new(y).parse
        codes = grammar.rules.map(&:code).compact

        expect(codes.count).to eq(1)
        expect(codes[0].s_value).to eq(<<~STR.chomp)
{
            func("}");
        }
        STR
      end
    end

    describe " ' in user code" do
      it do
        y = header + <<~INPUT
%%

program: class ;

class : keyword_class
        {
            func('}');
        }
      ;

%%
        INPUT
        grammar = Lrama::Parser.new(y).parse
        codes = grammar.rules.map(&:code).compact

        expect(codes.count).to eq(1)
        expect(codes[0].s_value).to eq(<<~STR.chomp)
{
            func('}');
        }
        STR
      end
    end

    describe "symbol number" do
      it "is not duplicated" do
        y = <<~INPUT
%{
// Prologue
%}

%union {
    int i;
    long l;
    char *str;
}

%token EOI 0 "EOI"
%token <i> keyword_class
%token <l> tNUMBER 6
%token <str> tSTRING
%token <i> keyword_end "end"
%token tPLUS  "+"
%token tMINUS "-"
%token tEQ    "="
%token tEQEQ  "=="

%%

program: class ;

class : keyword_class tSTRING keyword_end { code 1 }
      ;

%%

        INPUT
        grammar = Lrama::Parser.new(y).parse

        expect(grammar.terms.sort_by(&:number)).to eq([
          Sym.new(T.new(T::Ident, "EOI"),            "\"EOI\"",           0,                    nil, true,   0, false),
          Sym.new(T.new(T::Ident, "YYerror"),        "error",             1,                    nil, true, 256, false),
          Sym.new(T.new(T::Ident, "YYUNDEF"),        "\"invalid token\"", 2,                    nil, true, 257, false),
          Sym.new(T.new(T::Ident, "keyword_class"),  nil,                 3,   T.new(T::Tag, "<i>"), true, 258, false),
          Sym.new(T.new(T::Ident, "tNUMBER"),        nil,                 4,   T.new(T::Tag, "<l>"), true,   6, false),
          Sym.new(T.new(T::Ident, "tSTRING"),        nil,                 5, T.new(T::Tag, "<str>"), true, 259, false),
          Sym.new(T.new(T::Ident, "keyword_end"),    "\"end\"",           6,   T.new(T::Tag, "<i>"), true, 260, false),
          Sym.new(T.new(T::Ident, "tPLUS"),          "\"+\"",             7,                    nil, true, 261, false),
          Sym.new(T.new(T::Ident, "tMINUS"),         "\"-\"",             8,                    nil, true, 262, false),
          Sym.new(T.new(T::Ident, "tEQ"),            "\"=\"",             9,                    nil, true, 263, false),
          Sym.new(T.new(T::Ident, "tEQEQ"),          "\"==\"",           10,                    nil, true, 264, false),
        ])
      end

      it "tokens after precedence declarations have greater number than tokens defined by precedence declarations" do
        y = <<~INPUT
%{
// Prologue
%}

%union {
    int i;
    long l;
    char *str;
}

%token EOI 0 "EOI"
%token <i> keyword_class
%token <str> tSTRING
%token <i> keyword_end "end"
%token tEQ    "="

%left '&'

%token tEQEQ  "=="

%%

program: class ;

class : keyword_class tSTRING keyword_end { code 1 }
      ;

%%

        INPUT
        grammar = Lrama::Parser.new(y).parse

        expect(grammar.terms.sort_by(&:number)).to eq([
          Sym.new(T.new(T::Ident, "EOI"),            "\"EOI\"",           0,                    nil, true,   0, false, nil),
          Sym.new(T.new(T::Ident, "YYerror"),        "error",             1,                    nil, true, 256, false, nil),
          Sym.new(T.new(T::Ident, "YYUNDEF"),        "\"invalid token\"", 2,                    nil, true, 257, false, nil),
          Sym.new(T.new(T::Ident, "keyword_class"),  nil,                 3,   T.new(T::Tag, "<i>"), true, 258, false, nil),
          Sym.new(T.new(T::Ident, "tSTRING"),        nil,                 4, T.new(T::Tag, "<str>"), true, 259, false, nil),
          Sym.new(T.new(T::Ident, "keyword_end"),    "\"end\"",           5,   T.new(T::Tag, "<i>"), true, 260, false, nil),
          Sym.new(T.new(T::Ident, "tEQ"),            "\"=\"",             6,                    nil, true, 261, false, nil),
          Sym.new(T.new(T::Char,  "'&'"),            nil,                 7,                    nil, true,  38, false, Precedence.new(:left, 0)),
          Sym.new(T.new(T::Ident, "tEQEQ"),          "\"==\"",            8,                    nil, true, 262, false, nil),
        ])
      end
    end

    describe "user codes" do
      describe "" do
        it "is not duplicated" do
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
          grammar = Lrama::Parser.new(y).parse

          expect(grammar.rules).to eq([
            Rule.new(
              0,
              grammar.find_symbol_by_s_value!("$accept"),
              [
                grammar.find_symbol_by_s_value!("program"),
                grammar.find_symbol_by_s_value!("EOI"),
              ],
              nil,
              false,
              grammar.find_symbol_by_s_value!("EOI"),
              14,
            ),
            Rule.new(
              1,
              grammar.find_symbol_by_s_value!("program"),
              [
                grammar.find_symbol_by_s_value!("lambda"),
              ],
              nil,
              false,
              nil,
              14,
            ),
            Rule.new(
              2,
              grammar.find_symbol_by_s_value!("@1"),
              [],
              Code.new(:user_code, T.new(T::User_code, "{ $<int>1 = 1; $<int>$ = 2; }")),
              true,
              nil,
              17,
            ),
            Rule.new(
              3,
              grammar.find_symbol_by_s_value!("@2"),
              [],
              Code.new(:user_code, T.new(T::User_code, "{ $<int>$ = 3; }")),
              true,
              nil,
              18,
            ),
            Rule.new(
              4,
              grammar.find_symbol_by_s_value!("$@3"),
              [],
              Code.new(:user_code, T.new(T::User_code, "{ $<int>$ = 4; }")),
              true,
              nil,
              19,
            ),
            Rule.new(
              5,
              grammar.find_symbol_by_s_value!("$@4"),
              [],
              Code.new(:user_code, T.new(T::User_code, "{ 5; }")),
              true,
              nil,
              21,
            ),
            Rule.new(
              6,
              grammar.find_symbol_by_s_value!("lambda"),
              [
                grammar.find_symbol_by_s_value!("tLAMBDA"),
                grammar.find_symbol_by_s_value!("@1"),
                grammar.find_symbol_by_s_value!("@2"),
                grammar.find_symbol_by_s_value!("$@3"),
                grammar.find_symbol_by_s_value!("tARGS"),
                grammar.find_symbol_by_s_value!("$@4"),
                grammar.find_symbol_by_s_value!("tBODY"),
              ],
              Code.new(:user_code, T.new(T::User_code, "{ $2; $3; $5; $7; $$ = 1; }")),
              false,
              grammar.find_symbol_by_s_value!("tBODY"),
              16,
            ),
          ])
        end

        it "can parse action with %empty" do
          y = <<~INPUT
%{
// Prologue
%}

%union {
    int i;
}

%token EOI 0 "EOI"

%%

program: emp ;

emp: /* none */
      { $$; }
   | %empty
      { @$; }
   | %empty
      { @0; }
   ;
%%
          INPUT
          grammar = Lrama::Parser.new(y).parse

          expect(grammar.rules).to eq([
            Rule.new(
              0,
              grammar.find_symbol_by_s_value!("$accept"),
              [
                grammar.find_symbol_by_s_value!("program"),
                grammar.find_symbol_by_s_value!("EOI"),
              ],
              nil,
              false,
              grammar.find_symbol_by_s_value!("EOI"),
              13,
            ),
            Rule.new(
              1,
              grammar.find_symbol_by_s_value!("program"),
              [
                grammar.find_symbol_by_s_value!("emp"),
              ],
              nil,
              true,
              nil,
              13,
            ),
            Rule.new(
              2,
              grammar.find_symbol_by_s_value!("emp"),
              [
              ],
              Code.new(:user_code, T.new(T::User_code, "{ $$; }")),
              true,
              nil,
              16,
            ),
            Rule.new(
              3,
              grammar.find_symbol_by_s_value!("emp"),
              [
              ],
              Code.new(:user_code, T.new(T::User_code, "{ @$; }")),
              true,
              nil,
              18,
            ),
            Rule.new(
              4,
              grammar.find_symbol_by_s_value!("emp"),
              [
              ],
              Code.new(:user_code, T.new(T::User_code, "{ @0; }")),
              true,
              nil,
              20,
            ),
          ])
        end
      end
    end
  end

  describe "#fill_symbol_number" do
    it "fills token_id of Token::Char" do
      y = <<~INPUT
%{
// Prologue
%}

%union {
  int i;
}

%token '\\b' "BS"
%token '\\f' "FF"
%token '\\n' "LF"
%token '\\r' "CR"
%token '\\t' "HT"
%token '\\v' "VT"

%token <i> keyword_class
%token <i> tSTRING
%token <i> keyword_end

%%

program: class ;

class : keyword_class tSTRING keyword_end ;

%%
      INPUT
      grammar = Lrama::Parser.new(y).parse
      terms = grammar.terms.sort_by(&:number).map do |term|
        [term.id.s_value, term.token_id]
      end

      expect(terms).to eq([
        ["YYEOF", 0],
        ["YYerror", 256],
        ["YYUNDEF", 257],
        ["'\\b'", 8],
        ["'\\f'", 12],
        ["'\\n'", 10],
        ["'\\r'", 13],
        ["'\\t'", 9],
        ["'\\v'", 11],
        ["keyword_class", 258],
        ["tSTRING", 259],
        ["keyword_end", 260],
      ])
    end
  end

  describe "#normalize_rules" do
    describe "referring_symbol" do
      it "uses a tag specified in code" do
        y = <<~INPUT
%{
// Prologue
%}

%union {
  int i;
  long l;
}

%token <i> keyword_class
%token <i> tSTRING
%token <i> keyword_end

%%

program: class ;

class : keyword_class tSTRING keyword_end
        { $<l>$; }
      ;

%%
        INPUT
        grammar = Lrama::Parser.new(y).parse
        codes = grammar.rules.map(&:code)

        expect(codes.count).to eq(3)
        expect(codes[0]).to be nil
        expect(codes[1]).to be nil
        expect(codes[2].references.count).to eq(1)
        expect(codes[2].references[0].tag.s_value).to eq("<l>")
      end
    end
  end
end
