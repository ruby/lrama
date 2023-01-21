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
          ident_or_tags: [T.new(type: T::Tag, s_value: "<int>")],
          code: Code.new(type: :printer, token_code: T.new(type: T::User_code, s_value: "{\n    print_int();\n}")),
          lineno: 15
        ),
        Printer.new(
          ident_or_tags: [T.new(type: T::Ident, s_value: "tNUMBER"), T.new(type: T::Ident, s_value: "tSTRING")],
          code: Code.new(type: :printer, token_code: T.new(type: T::User_code, s_value: "{\n    print_token();\n}")),
          lineno: 18
        ),
      ])
      expect(grammar.lex_param).to eq("{struct lex_params *p}")
      expect(grammar.parse_param).to eq("{struct parse_params *p}")
      expect(grammar.initial_action).to eq(Code.new(type: :initial_action, token_code: T.new(type: T::User_code, s_value: "{\n    initial_action_func(@$);\n}")))
      expect(grammar.symbols.sort_by(&:number)).to eq([
        Sym.new(id: T.new(type: T::Ident, s_value: "EOI"),            alias_name: "\"EOI\"",                  number:  0, tag: nil,                                   term: true, token_id:   0, nullable: false, precedence: nil,                                            printer: nil),
        Sym.new(id: T.new(type: T::Ident, s_value: "YYerror"),        alias_name: "error",                    number:  1, tag: nil,                                   term: true, token_id: 256, nullable: false, precedence: nil,                                            printer: nil),
        Sym.new(id: T.new(type: T::Ident, s_value: "YYUNDEF"),        alias_name: "\"invalid token\"",        number:  2, tag: nil,                                   term: true, token_id: 257, nullable: false, precedence: nil,                                            printer: nil),
        Sym.new(id: T.new(type: T::Char, s_value:  "'\\\\'"),         alias_name: "\"backslash\"",            number:  3, tag: T.new(type: T::Tag, s_value: "<i>"),   term: true, token_id:  92, nullable: false, precedence: nil,                                            printer: nil),
        Sym.new(id: T.new(type: T::Char, s_value:  "'\\13'"),         alias_name: "\"escaped vertical tab\"", number:  4, tag: T.new(type: T::Tag, s_value: "<i>"),   term: true, token_id:  11, nullable: false, precedence: nil,                                            printer: nil),
        Sym.new(id: T.new(type: T::Ident, s_value: "keyword_class"),  alias_name: nil,                        number:  5, tag: T.new(type: T::Tag, s_value: "<i>"),   term: true, token_id: 258, nullable: false, precedence: nil,                                            printer: nil),
        Sym.new(id: T.new(type: T::Ident, s_value: "keyword_class2"), alias_name: nil,                        number:  6, tag: T.new(type: T::Tag, s_value: "<i>"),   term: true, token_id: 259, nullable: false, precedence: nil,                                            printer: nil),
        Sym.new(id: T.new(type: T::Ident, s_value: "tNUMBER"),        alias_name: nil,                        number:  7, tag: T.new(type: T::Tag, s_value: "<l>"),   term: true, token_id: 260, nullable: false, precedence: nil,                                            printer: grammar.printers[1]),
        Sym.new(id: T.new(type: T::Ident, s_value: "tSTRING"),        alias_name: nil,                        number:  8, tag: T.new(type: T::Tag, s_value: "<str>"), term: true, token_id: 261, nullable: false, precedence: nil,                                            printer: grammar.printers[1]),
        Sym.new(id: T.new(type: T::Ident, s_value: "keyword_end"),    alias_name: "\"end\"",                  number:  9, tag: T.new(type: T::Tag, s_value: "<i>"),   term: true, token_id: 262, nullable: false, precedence: nil,                                            printer: nil),
        Sym.new(id: T.new(type: T::Ident, s_value: "tPLUS"),          alias_name: "\"+\"",                    number: 10, tag: nil,                                   term: true, token_id: 263, nullable: false, precedence: Precedence.new(type: :left,     precedence: 1), printer: nil),
        Sym.new(id: T.new(type: T::Ident, s_value: "tMINUS"),         alias_name: "\"-\"",                    number: 11, tag: nil,                                   term: true, token_id: 264, nullable: false, precedence: Precedence.new(type: :left,     precedence: 1), printer: nil),
        Sym.new(id: T.new(type: T::Ident, s_value: "tEQ"),            alias_name: "\"=\"",                    number: 12, tag: nil,                                   term: true, token_id: 265, nullable: false, precedence: Precedence.new(type: :right,    precedence: 2), printer: nil),
        Sym.new(id: T.new(type: T::Ident, s_value: "tEQEQ"),          alias_name: "\"==\"",                   number: 13, tag: nil,                                   term: true, token_id: 266, nullable: false, precedence: Precedence.new(type: :nonassoc, precedence: 0), printer: nil),
        Sym.new(id: T.new(type: T::Char, s_value:  "'>'"),            alias_name: nil,                        number: 14, tag: nil,                                   term: true, token_id:  62, nullable: false, precedence: Precedence.new(type: :left,     precedence: 1), printer: nil),
        Sym.new(id: T.new(type: T::Char, s_value:  "'+'"),            alias_name: nil,                        number: 15, tag: nil,                                   term: true, token_id:  43, nullable: false, precedence: nil,                                            printer: nil),
        Sym.new(id: T.new(type: T::Char, s_value:  "'-'"),            alias_name: nil,                        number: 16, tag: nil,                                   term: true, token_id:  45, nullable: false, precedence: nil,                                            printer: nil),
        Sym.new(id: T.new(type: T::Char, s_value:  "'!'"),            alias_name: nil,                        number: 17, tag: nil,                                   term: true, token_id:  33, nullable: false, precedence: nil,                                            printer: nil),
        Sym.new(id: T.new(type: T::Char, s_value:  "'?'"),            alias_name: nil,                        number: 18, tag: nil,                                   term: true, token_id:  63, nullable: false, precedence: nil,                                            printer: nil),

        Sym.new(id: T.new(type: T::Ident, s_value: "$accept"),   alias_name: nil, number: 19, tag: nil,                                 term: false, token_id:  0, nullable: false, precedence: nil, printer: nil),
        Sym.new(id: T.new(type: T::Ident, s_value: "program"),   alias_name: nil, number: 20, tag: nil,                                 term: false, token_id:  1, nullable: false, precedence: nil, printer: nil),
        Sym.new(id: T.new(type: T::Ident, s_value: "class"),     alias_name: nil, number: 21, tag: T.new(type: T::Tag, s_value: "<i>"), term: false, token_id:  2, nullable: false, precedence: nil, printer: nil),
        Sym.new(id: T.new(type: T::Ident, s_value: "$@1"),       alias_name: nil, number: 22, tag: nil,                                 term: false, token_id:  3, nullable:  true, precedence: nil, printer: nil),
        Sym.new(id: T.new(type: T::Ident, s_value: "$@2"),       alias_name: nil, number: 23, tag: nil,                                 term: false, token_id:  4, nullable:  true, precedence: nil, printer: nil),
        Sym.new(id: T.new(type: T::Ident, s_value: "$@3"),       alias_name: nil, number: 24, tag: nil,                                 term: false, token_id:  5, nullable:  true, precedence: nil, printer: nil),
        Sym.new(id: T.new(type: T::Ident, s_value: "$@4"),       alias_name: nil, number: 25, tag: nil,                                 term: false, token_id:  6, nullable:  true, precedence: nil, printer: nil),
        Sym.new(id: T.new(type: T::Ident, s_value: "strings_1"), alias_name: nil, number: 26, tag: nil,                                 term: false, token_id:  7, nullable: false, precedence: nil, printer: nil),
        Sym.new(id: T.new(type: T::Ident, s_value: "strings_2"), alias_name: nil, number: 27, tag: nil,                                 term: false, token_id:  8, nullable: false, precedence: nil, printer: nil),
        Sym.new(id: T.new(type: T::Ident, s_value: "string_1"),  alias_name: nil, number: 28, tag: nil,                                 term: false, token_id:  9, nullable: false, precedence: nil, printer: nil),
        Sym.new(id: T.new(type: T::Ident, s_value: "string_2"),  alias_name: nil, number: 29, tag: nil,                                 term: false, token_id: 10, nullable: false, precedence: nil, printer: nil),
        Sym.new(id: T.new(type: T::Ident, s_value: "string"),    alias_name: nil, number: 30, tag: nil,                                 term: false, token_id: 11, nullable: false, precedence: nil, printer: nil),
      ])
      expect(grammar.types).to eq([Type.new(id: T.new(type: T::Ident, s_value: "class"), tag: T.new(type: T::Tag, s_value: "<i>"))])
      expect(grammar._rules).to eq([
        [
          T.new(type: T::Ident, s_value: "program"),
          [
            T.new(type: T::Ident, s_value: "class"),
          ],
          57,
        ],
        [
          T.new(type: T::Ident, s_value: "program"),
          [
            T.new(type: T::Char, s_value: "'+'"),
            T.new(type: T::Ident, s_value: "strings_1"),
          ],
          58,
        ],
        [
          T.new(type: T::Ident, s_value: "program"),
          [
            T.new(type: T::Char, s_value: "'-'"),
            T.new(type: T::Ident, s_value: "strings_2"),
          ],
          59,
        ],
        [
          T.new(type: T::Ident, s_value: "class"),
          [
            T.new(type: T::Ident, s_value: "keyword_class"),
            T.new(type: T::Ident, s_value: "tSTRING"),
            T.new(type: T::Ident, s_value: "keyword_end"),
            grammar.find_symbol_by_s_value!("tPLUS"),
            T.new(type: T::User_code, s_value: "{ code 1 }"),
          ],
          62,
        ],
        [
          T.new(type: T::Ident, s_value: "class"),
          [
            T.new(type: T::Ident, s_value: "keyword_class"),
            T.new(type: T::User_code, s_value: "{ code 2 }"),
            T.new(type: T::Ident, s_value: "tSTRING"),
            T.new(type: T::Char, s_value: "'!'"),
            T.new(type: T::Ident, s_value: "keyword_end"),
            T.new(type: T::User_code, s_value: "{ code 3 }"),
            grammar.find_symbol_by_s_value!("tEQ"),
          ],
          64,
        ],
        [
          T.new(type: T::Ident, s_value: "class"),
          [
            T.new(type: T::Ident, s_value: "keyword_class"),
            T.new(type: T::User_code, s_value: "{ code 4 }"),
            T.new(type: T::Ident, s_value: "tSTRING"),
            T.new(type: T::Char, s_value: "'?'"),
            T.new(type: T::Ident, s_value: "keyword_end"),
            T.new(type: T::User_code, s_value: "{ code 5 }"),
            grammar.find_symbol_by_s_value!("'>'"),
          ],
          65,
        ],
        [
          T.new(type: T::Ident, s_value: "strings_1"),
          [
            T.new(type: T::Ident, s_value: "string_1"),
          ],
          68,
        ],
        [
          T.new(type: T::Ident, s_value: "strings_2"),
          [
            T.new(type: T::Ident, s_value: "string_1"),
          ],
          71,
        ],
        [
          T.new(type: T::Ident, s_value: "strings_2"),
          [
            T.new(type: T::Ident, s_value: "string_2"),
          ],
          72,
        ],
        [
          T.new(type: T::Ident, s_value: "string_1"),
          [
            T.new(type: T::Ident, s_value: "string"),
          ],
          75,
        ],
        [
          T.new(type: T::Ident, s_value: "string_2"),
          [
            T.new(type: T::Ident, s_value: "string"),
            T.new(type: T::Char, s_value: "'+'"),
          ],
          78,
        ],
        [
          T.new(type: T::Ident, s_value: "string"),
          [
            T.new(type: T::Ident, s_value: "tSTRING")
          ],
          81,
        ],
      ])
      expect(grammar.rules).to eq([
        Rule.new(
          id: 0,
          lhs: grammar.find_symbol_by_s_value!("$accept"),
          rhs: [
            grammar.find_symbol_by_s_value!("program"),
            grammar.find_symbol_by_s_value!("EOI"),
          ],
          code: nil,
          nullable: false,
          precedence_sym: grammar.find_symbol_by_s_value!("EOI"),
          lineno: 57,
        ),
        Rule.new(
          id: 1,
          lhs: grammar.find_symbol_by_s_value!("program"),
          rhs: [
            grammar.find_symbol_by_s_value!("class"),
          ],
          code: nil,
          nullable: false,
          precedence_sym: nil,
          lineno: 57,
        ),
        Rule.new(
          id: 2,
          lhs: grammar.find_symbol_by_s_value!("program"),
          rhs: [
            grammar.find_symbol_by_s_value!("'+'"),
            grammar.find_symbol_by_s_value!("strings_1"),
          ],
          code: nil,
          nullable: false,
          precedence_sym: grammar.find_symbol_by_s_value!("'+'"),
          lineno: 58,
        ),
        Rule.new(
          id: 3,
          lhs: grammar.find_symbol_by_s_value!("program"),
          rhs: [
            grammar.find_symbol_by_s_value!("'-'"),
            grammar.find_symbol_by_s_value!("strings_2"),
          ],
          code: nil,
          nullable: false,
          precedence_sym: grammar.find_symbol_by_s_value!("'-'"),
          lineno: 59,
        ),
        Rule.new(
          id: 4,
          lhs: grammar.find_symbol_by_s_value!("class"),
          rhs: [
            grammar.find_symbol_by_s_value!("keyword_class"),
            grammar.find_symbol_by_s_value!("tSTRING"),
            grammar.find_symbol_by_s_value!("keyword_end"),
          ],
          code: Code.new(type: :user_code, token_code: T.new(type: T::User_code, s_value: "{ code 1 }")),
          nullable: false,
          precedence_sym: grammar.find_symbol_by_s_value!("tPLUS"),
          lineno: 62,
        ),
        Rule.new(
          id: 5,
          lhs: grammar.find_symbol_by_s_value!("$@1"),
          rhs: [],
          code: Code.new(type: :user_code, token_code: T.new(type: T::User_code, s_value: "{ code 2 }")),
          nullable: true,
          precedence_sym: nil,
          lineno: 64,
        ),
        Rule.new(
          id: 6,
          lhs: grammar.find_symbol_by_s_value!("$@2"),
          rhs: [],
          code: Code.new(type: :user_code, token_code: T.new(type: T::User_code, s_value: "{ code 3 }")),
          nullable: true,
          precedence_sym: nil,
          lineno: 64,
        ),
        Rule.new(
          id: 7,
          lhs: grammar.find_symbol_by_s_value!("class"),
          rhs: [
            grammar.find_symbol_by_s_value!("keyword_class"),
            grammar.find_symbol_by_s_value!("$@1"),
            grammar.find_symbol_by_s_value!("tSTRING"),
            grammar.find_symbol_by_s_value!("'!'"),
            grammar.find_symbol_by_s_value!("keyword_end"),
            grammar.find_symbol_by_s_value!("$@2"),
          ],
          code: nil,
          nullable: false,
          precedence_sym: grammar.find_symbol_by_s_value!("tEQ"),
          lineno: 64,
        ),
        Rule.new(
          id: 8,
          lhs: grammar.find_symbol_by_s_value!("$@3"),
          rhs: [],
          code: Code.new(type: :user_code, token_code: T.new(type: T::User_code, s_value: "{ code 4 }")),
          nullable: true,
          precedence_sym: nil,
          lineno: 65,
        ),
        Rule.new(
          id: 9,
          lhs: grammar.find_symbol_by_s_value!("$@4"),
          rhs: [],
          code: Code.new(type: :user_code, token_code: T.new(type: T::User_code, s_value: "{ code 5 }")),
          nullable: true,
          precedence_sym: nil,
          lineno: 65,
        ),
        Rule.new(
          id: 10,
          lhs: grammar.find_symbol_by_s_value!("class"),
          rhs: [
            grammar.find_symbol_by_s_value!("keyword_class"),
            grammar.find_symbol_by_s_value!("$@3"),
            grammar.find_symbol_by_s_value!("tSTRING"),
            grammar.find_symbol_by_s_value!("'?'"),
            grammar.find_symbol_by_s_value!("keyword_end"),
            grammar.find_symbol_by_s_value!("$@4"),
          ],
          code: nil,
          nullable: false,
          precedence_sym: grammar.find_symbol_by_s_value!("'>'"),
          lineno: 65,
        ),
        Rule.new(
          id: 11,
          lhs: grammar.find_symbol_by_s_value!("strings_1"),
          rhs: [
            grammar.find_symbol_by_s_value!("string_1"),
          ],
          code: nil,
          nullable: false,
          precedence_sym: nil,
          lineno: 68,
        ),
        Rule.new(
          id: 12,
          lhs: grammar.find_symbol_by_s_value!("strings_2"),
          rhs: [
            grammar.find_symbol_by_s_value!("string_1"),
          ],
          code: nil,
          nullable: false,
          precedence_sym: nil,
          lineno: 71,
        ),
        Rule.new(
          id: 13,
          lhs: grammar.find_symbol_by_s_value!("strings_2"),
          rhs: [
            grammar.find_symbol_by_s_value!("string_2"),
          ],
          code: nil,
          nullable: false,
          precedence_sym: nil,
          lineno: 72,
        ),
        Rule.new(
          id: 14,
          lhs: grammar.find_symbol_by_s_value!("string_1"),
          rhs: [
            grammar.find_symbol_by_s_value!("string"),
          ],
          code: nil,
          nullable: false,
          precedence_sym: nil,
          lineno: 75,
        ),
        Rule.new(
          id: 15,
          lhs: grammar.find_symbol_by_s_value!("string_2"),
          rhs: [
            grammar.find_symbol_by_s_value!("string"),
            grammar.find_symbol_by_s_value!("'+'"),
          ],
          code: nil,
          nullable: false,
          precedence_sym: grammar.find_symbol_by_s_value!("'+'"),
          lineno: 78,
        ),
        Rule.new(
          id: 16,
          lhs: grammar.find_symbol_by_s_value!("string"),
          rhs: [
            grammar.find_symbol_by_s_value!("tSTRING"),
          ],
          code: nil,
          nullable: false,
          precedence_sym: grammar.find_symbol_by_s_value!("tSTRING"),
          lineno: 81,
        ),
      ])
    end

    it "nullable" do
      y = File.read(fixture_path("common/nullable.y"))
      grammar = Lrama::Parser.new(y).parse

      expect(grammar.nterms.sort_by(&:number)).to eq([
        Sym.new(id: T.new(type: T::Ident, s_value: "$accept"),       alias_name: nil, number:  6, tag: nil, term: false, token_id: 0, nullable: false),
        Sym.new(id: T.new(type: T::Ident, s_value: "program"),       alias_name: nil, number:  7, tag: nil, term: false, token_id: 1, nullable: true),
        Sym.new(id: T.new(type: T::Ident, s_value: "stmt"),          alias_name: nil, number:  8, tag: nil, term: false, token_id: 2, nullable: true),
        Sym.new(id: T.new(type: T::Ident, s_value: "expr"),          alias_name: nil, number:  9, tag: nil, term: false, token_id: 3, nullable: false),
        Sym.new(id: T.new(type: T::Ident, s_value: "opt_expr"),      alias_name: nil, number: 10, tag: nil, term: false, token_id: 4, nullable: true),
        Sym.new(id: T.new(type: T::Ident, s_value: "opt_semicolon"), alias_name: nil, number: 11, tag: nil, term: false, token_id: 5, nullable: true),
        Sym.new(id: T.new(type: T::Ident, s_value: "opt_colon"),     alias_name: nil, number: 12, tag: nil, term: false, token_id: 6, nullable: true),
      ])
      expect(grammar.rules).to eq([
        Rule.new(
          id: 0,
          lhs: grammar.find_symbol_by_s_value!("$accept"),
          rhs: [
            grammar.find_symbol_by_s_value!("program"),
            grammar.find_symbol_by_s_value!("YYEOF"),
          ],
          code: nil,
          nullable: false,
          precedence_sym: grammar.find_symbol_by_s_value!("YYEOF"),
          lineno: 15,
        ),
        Rule.new(
          id: 1,
          lhs: grammar.find_symbol_by_s_value!("program"),
          rhs: [
            grammar.find_symbol_by_s_value!("stmt"),
          ],
          code: nil,
          nullable: true,
          precedence_sym: nil,
          lineno: 15,
        ),
        Rule.new(
          id: 2,
          lhs: grammar.find_symbol_by_s_value!("stmt"),
          rhs: [
            grammar.find_symbol_by_s_value!("expr"),
            grammar.find_symbol_by_s_value!("opt_semicolon"),
          ],
          code: nil,
          nullable: false,
          precedence_sym: nil,
          lineno: 17,
        ),
        Rule.new(
          id: 3,
          lhs: grammar.find_symbol_by_s_value!("stmt"),
          rhs: [
            grammar.find_symbol_by_s_value!("opt_expr"),
            grammar.find_symbol_by_s_value!("opt_colon"),
          ],
          code: nil,
          nullable: true,
          precedence_sym: nil,
          lineno: 18,
        ),
        Rule.new(
          id: 4,
          lhs: grammar.find_symbol_by_s_value!("stmt"),
          rhs: [],
          code: nil,
          nullable: true,
          precedence_sym: nil,
          lineno: 19,
        ),
        Rule.new(
          id: 5,
          lhs: grammar.find_symbol_by_s_value!("expr"),
          rhs: [
            grammar.find_symbol_by_s_value!("tNUMBER"),
          ],
          code: nil,
          nullable: false,
          precedence_sym: grammar.find_symbol_by_s_value!("tNUMBER"),
          lineno: 22,
        ),
        Rule.new(
          id: 6,
          lhs: grammar.find_symbol_by_s_value!("opt_expr"),
          rhs: [],
          code: nil,
          nullable: true,
          precedence_sym: nil,
          lineno: 24,
        ),
        Rule.new(
          id: 7,
          lhs: grammar.find_symbol_by_s_value!("opt_expr"),
          rhs: [
            grammar.find_symbol_by_s_value!("expr"),
          ],
          code: nil,
          nullable: false,
          precedence_sym: nil,
          lineno: 25,
        ),
        Rule.new(
          id: 8,
          lhs: grammar.find_symbol_by_s_value!("opt_semicolon"),
          rhs: [],
          code: nil,
          nullable: true,
          precedence_sym: nil,
          lineno: 28,
        ),
        Rule.new(
          id: 9,
          lhs: grammar.find_symbol_by_s_value!("opt_semicolon"),
          rhs: [
            grammar.find_symbol_by_s_value!("';'"),
          ],
          code: nil,
          nullable: false,
          precedence_sym: grammar.find_symbol_by_s_value!("';'"),
          lineno: 29,
        ),
        Rule.new(
          id: 10,
          lhs: grammar.find_symbol_by_s_value!("opt_colon"),
          rhs: [],
          code: nil,
          nullable: true,
          precedence_sym: nil,
          lineno: 32,
        ),
        Rule.new(
          id: 11,
          lhs: grammar.find_symbol_by_s_value!("opt_colon"),
          rhs: [
            grammar.find_symbol_by_s_value!("'.'"),
          ],
          code: nil,
          nullable: false,
          precedence_sym: grammar.find_symbol_by_s_value!("'.'"),
          lineno: 33,
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
          Sym.new(id: T.new(type: T::Ident, s_value: "EOI"),           alias_name: "\"EOI\"",           number:  0, tag: nil,                                   term: true, token_id:   0, nullable: false, precedence: nil),
          Sym.new(id: T.new(type: T::Ident, s_value: "YYerror"),       alias_name: "error",             number:  1, tag: nil,                                   term: true, token_id: 256, nullable: false, precedence: nil),
          Sym.new(id: T.new(type: T::Ident, s_value: "YYUNDEF"),       alias_name: "\"invalid token\"", number:  2, tag: nil,                                   term: true, token_id: 257, nullable: false, precedence: nil),
          Sym.new(id: T.new(type: T::Ident, s_value: "keyword_class"), alias_name: nil,                 number:  3, tag: T.new(type: T::Tag, s_value: "<i>"),   term: true, token_id: 258, nullable: false, precedence: nil),
          Sym.new(id: T.new(type: T::Ident, s_value: "tNUMBER"),       alias_name: nil,                 number:  4, tag: T.new(type: T::Tag, s_value: "<l>"),   term: true, token_id: 259, nullable: false, precedence: nil),
          Sym.new(id: T.new(type: T::Ident, s_value: "tSTRING"),       alias_name: nil,                 number:  5, tag: T.new(type: T::Tag, s_value: "<str>"), term: true, token_id: 260, nullable: false, precedence: nil),
          Sym.new(id: T.new(type: T::Ident, s_value: "keyword_end"),   alias_name: "\"end\"",           number:  6, tag: T.new(type: T::Tag, s_value: "<i>"),   term: true, token_id: 261, nullable: false, precedence: nil),
          Sym.new(id: T.new(type: T::Ident, s_value: "tPLUS"),         alias_name: "\"+\"",             number:  7, tag: nil,                                   term: true, token_id: 262, nullable: false, precedence: Precedence.new(type: :left,     precedence: 1)),
          Sym.new(id: T.new(type: T::Ident, s_value: "tMINUS"),        alias_name: "\"-\"",             number:  8, tag: nil,                                   term: true, token_id: 263, nullable: false, precedence: Precedence.new(type: :left,     precedence: 1)),
          Sym.new(id: T.new(type: T::Ident, s_value: "tEQ"),           alias_name: "\"=\"",             number:  9, tag: nil,                                   term: true, token_id: 264, nullable: false, precedence: Precedence.new(type: :right,    precedence: 2)),
          Sym.new(id: T.new(type: T::Ident, s_value: "tEQEQ"),         alias_name: "\"==\"",            number: 10, tag: nil,                                   term: true, token_id: 265, nullable: false, precedence: Precedence.new(type: :nonassoc, precedence: 0)),
        ])
        expect(grammar._rules).to eq([
          [
            T.new(type: T::Ident, s_value: "program"),
            [
              T.new(type: T::Ident, s_value: "class")
            ],
            29,
          ],
          [
            T.new(type: T::Ident, s_value: "class"),
            [
              T.new(type: T::Ident, s_value: "keyword_class"),
              T.new(type: T::Ident, s_value: "tSTRING"),
              T.new(type: T::Ident, s_value: "keyword_end"),
              T.new(type: T::User_code, s_value: "{ code 1 }"),
            ],
            31,
          ],
          [
            T.new(type: T::Ident, s_value: "class"),
            [
              T.new(type: T::Ident, s_value: "error")
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
          Sym.new(id: T.new(type: T::Ident, s_value: "$accept"), alias_name: nil, number: 11, tag: nil,                                 term: false, token_id: 0, nullable: false),
          Sym.new(id: T.new(type: T::Ident, s_value: "program"), alias_name: nil, number: 12, tag: nil,                                 term: false, token_id: 1, nullable: false),
          Sym.new(id: T.new(type: T::Ident, s_value: "class"),   alias_name: nil, number: 13, tag: T.new(type: T::Tag, s_value: "<i>"), term: false, token_id: 2, nullable: false),
          Sym.new(id: T.new(type: T::Ident, s_value: "$@1"),     alias_name: nil, number: 14, tag: nil,                                 term: false, token_id: 3, nullable: true),
          Sym.new(id: T.new(type: T::Ident, s_value: "$@2"),     alias_name: nil, number: 15, tag: nil,                                 term: false, token_id: 4, nullable: true),
        ])
        expect(grammar.rules).to eq([
          Rule.new(
            id: 0,
            lhs: grammar.find_symbol_by_s_value!("$accept"),
            rhs: [
              grammar.find_symbol_by_s_value!("program"),
              grammar.find_symbol_by_s_value!("EOI"),
            ],
            code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("EOI"),
            lineno: 29,
          ),
          Rule.new(
            id: 1,
            lhs: grammar.find_symbol_by_s_value!("program"),
            rhs: [
              grammar.find_symbol_by_s_value!("class"),
            ],
            code: nil,
            nullable: false,
            precedence_sym: nil,
            lineno: 29,
          ),
          Rule.new(
            id: 2,
            lhs: grammar.find_symbol_by_s_value!("$@1"),
            rhs: [],
            code: Code.new(type: :user_code, token_code: T.new(type: T::User_code, s_value: "{ code 1 }")),
            nullable: true,
            precedence_sym: nil,
            lineno: 31,
          ),
          Rule.new(
            id: 3,
            lhs: grammar.find_symbol_by_s_value!("$@2"),
            rhs: [],
            code: Code.new(type: :user_code, token_code: T.new(type: T::User_code, s_value: "{ code 2 }")),
            nullable: true,
            precedence_sym: nil,
            lineno: 31,
          ),
          Rule.new(
            id: 4,
            lhs: grammar.find_symbol_by_s_value!("class"),
            rhs: [
              grammar.find_symbol_by_s_value!("keyword_class"),
              grammar.find_symbol_by_s_value!("$@1"),
              grammar.find_symbol_by_s_value!("tSTRING"),
              grammar.find_symbol_by_s_value!("$@2"),
              grammar.find_symbol_by_s_value!("keyword_end"),
            ],
            code: Code.new(type: :user_code, token_code: T.new(type: T::User_code, s_value: "{ code 3 }")),
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("keyword_end"),
            lineno: 31,
          ),
          Rule.new(
            id: 5,
            lhs: grammar.find_symbol_by_s_value!("class"),
            rhs: [
              grammar.find_symbol_by_s_value!("keyword_class"),
              grammar.find_symbol_by_s_value!("tSTRING"),
              grammar.find_symbol_by_s_value!("keyword_end"),
            ],
            code: Code.new(type: :user_code, token_code: T.new(type: T::User_code, s_value: "{ code 4 }")),
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("keyword_end"),
            lineno: 32,
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
          Sym.new(id: T.new(type: T::Ident, s_value: "EOI"),           alias_name: "\"EOI\"",           number:  0, tag: nil,                                   term: true, token_id:   0, nullable: false),
          Sym.new(id: T.new(type: T::Ident, s_value: "YYerror"),       alias_name: "error",             number:  1, tag: nil,                                   term: true, token_id: 256, nullable: false),
          Sym.new(id: T.new(type: T::Ident, s_value: "YYUNDEF"),       alias_name: "\"invalid token\"", number:  2, tag: nil,                                   term: true, token_id: 257, nullable: false),
          Sym.new(id: T.new(type: T::Ident, s_value: "keyword_class"), alias_name: nil,                 number:  3, tag: T.new(type: T::Tag, s_value: "<i>"),   term: true, token_id: 258, nullable: false),
          Sym.new(id: T.new(type: T::Ident, s_value: "tNUMBER"),       alias_name: nil,                 number:  4, tag: T.new(type: T::Tag, s_value: "<l>"),   term: true, token_id:   6, nullable: false),
          Sym.new(id: T.new(type: T::Ident, s_value: "tSTRING"),       alias_name: nil,                 number:  5, tag: T.new(type: T::Tag, s_value: "<str>"), term: true, token_id: 259, nullable: false),
          Sym.new(id: T.new(type: T::Ident, s_value: "keyword_end"),   alias_name: "\"end\"",           number:  6, tag: T.new(type: T::Tag, s_value: "<i>"),   term: true, token_id: 260, nullable: false),
          Sym.new(id: T.new(type: T::Ident, s_value: "tPLUS"),         alias_name: "\"+\"",             number:  7, tag: nil,                                   term: true, token_id: 261, nullable: false),
          Sym.new(id: T.new(type: T::Ident, s_value: "tMINUS"),        alias_name: "\"-\"",             number:  8, tag: nil,                                   term: true, token_id: 262, nullable: false),
          Sym.new(id: T.new(type: T::Ident, s_value: "tEQ"),           alias_name: "\"=\"",             number:  9, tag: nil,                                   term: true, token_id: 263, nullable: false),
          Sym.new(id: T.new(type: T::Ident, s_value: "tEQEQ"),         alias_name: "\"==\"",            number: 10, tag: nil,                                   term: true, token_id: 264, nullable: false),
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
          Sym.new(id: T.new(type: T::Ident, s_value: "EOI"),           alias_name: "\"EOI\"",           number: 0, tag: nil,                                   term: true, token_id:   0, nullable: false, precedence: nil),
          Sym.new(id: T.new(type: T::Ident, s_value: "YYerror"),       alias_name: "error",             number: 1, tag: nil,                                   term: true, token_id: 256, nullable: false, precedence: nil),
          Sym.new(id: T.new(type: T::Ident, s_value: "YYUNDEF"),       alias_name: "\"invalid token\"", number: 2, tag: nil,                                   term: true, token_id: 257, nullable: false, precedence: nil),
          Sym.new(id: T.new(type: T::Ident, s_value: "keyword_class"), alias_name: nil,                 number: 3, tag: T.new(type: T::Tag, s_value: "<i>"),   term: true, token_id: 258, nullable: false, precedence: nil),
          Sym.new(id: T.new(type: T::Ident, s_value: "tSTRING"),       alias_name: nil,                 number: 4, tag: T.new(type: T::Tag, s_value: "<str>"), term: true, token_id: 259, nullable: false, precedence: nil),
          Sym.new(id: T.new(type: T::Ident, s_value: "keyword_end"),   alias_name: "\"end\"",           number: 5, tag: T.new(type: T::Tag, s_value: "<i>"),   term: true, token_id: 260, nullable: false, precedence: nil),
          Sym.new(id: T.new(type: T::Ident, s_value: "tEQ"),           alias_name: "\"=\"",             number: 6, tag: nil,                                   term: true, token_id: 261, nullable: false, precedence: nil),
          Sym.new(id: T.new(type: T::Char, s_value:  "'&'"),           alias_name: nil,                 number: 7, tag: nil,                                   term: true, token_id:  38, nullable: false, precedence: Precedence.new(type: :left, precedence: 0)),
          Sym.new(id: T.new(type: T::Ident, s_value: "tEQEQ"),         alias_name: "\"==\"",            number: 8, tag: nil,                                   term: true, token_id: 262, nullable: false, precedence: nil),
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
              id: 0,
              lhs: grammar.find_symbol_by_s_value!("$accept"),
              rhs: [
                grammar.find_symbol_by_s_value!("program"),
                grammar.find_symbol_by_s_value!("EOI"),
              ],
              code: nil,
              nullable: false,
              precedence_sym: grammar.find_symbol_by_s_value!("EOI"),
              lineno: 14,
            ),
            Rule.new(
              id: 1,
              lhs: grammar.find_symbol_by_s_value!("program"),
              rhs: [
                grammar.find_symbol_by_s_value!("lambda"),
              ],
              code: nil,
              nullable: false,
              precedence_sym: nil,
              lineno: 14,
            ),
            Rule.new(
              id: 2,
              lhs: grammar.find_symbol_by_s_value!("@1"),
              rhs: [],
              code: Code.new(type: :user_code, token_code: T.new(type: T::User_code, s_value: "{ $<int>1 = 1; $<int>$ = 2; }")),
              nullable: true,
              precedence_sym: nil,
              lineno: 17,
            ),
            Rule.new(
              id: 3,
              lhs: grammar.find_symbol_by_s_value!("@2"),
              rhs: [],
              code: Code.new(type: :user_code, token_code: T.new(type: T::User_code, s_value: "{ $<int>$ = 3; }")),
              nullable: true,
              precedence_sym: nil,
              lineno: 18,
            ),
            Rule.new(
              id: 4,
              lhs: grammar.find_symbol_by_s_value!("$@3"),
              rhs: [],
              code: Code.new(type: :user_code, token_code: T.new(type: T::User_code, s_value: "{ $<int>$ = 4; }")),
              nullable: true,
              precedence_sym: nil,
              lineno: 19,
            ),
            Rule.new(
              id: 5,
              lhs: grammar.find_symbol_by_s_value!("$@4"),
              rhs: [],
              code: Code.new(type: :user_code, token_code: T.new(type: T::User_code, s_value: "{ 5; }")),
              nullable: true,
              precedence_sym: nil,
              lineno: 21,
            ),
            Rule.new(
              id: 6,
              lhs: grammar.find_symbol_by_s_value!("lambda"),
              rhs: [
                grammar.find_symbol_by_s_value!("tLAMBDA"),
                grammar.find_symbol_by_s_value!("@1"),
                grammar.find_symbol_by_s_value!("@2"),
                grammar.find_symbol_by_s_value!("$@3"),
                grammar.find_symbol_by_s_value!("tARGS"),
                grammar.find_symbol_by_s_value!("$@4"),
                grammar.find_symbol_by_s_value!("tBODY"),
              ],
              code: Code.new(type: :user_code, token_code: T.new(type: T::User_code, s_value: "{ $2; $3; $5; $7; $$ = 1; }")),
              nullable: false,
              precedence_sym: grammar.find_symbol_by_s_value!("tBODY"),
              lineno: 16,
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
              id: 0,
              lhs: grammar.find_symbol_by_s_value!("$accept"),
              rhs: [
                grammar.find_symbol_by_s_value!("program"),
                grammar.find_symbol_by_s_value!("EOI"),
              ],
              code: nil,
              nullable: false,
              precedence_sym: grammar.find_symbol_by_s_value!("EOI"),
              lineno: 13,
            ),
            Rule.new(
              id: 1,
              lhs: grammar.find_symbol_by_s_value!("program"),
              rhs: [
                grammar.find_symbol_by_s_value!("emp"),
              ],
              code: nil,
              nullable: true,
              precedence_sym: nil,
              lineno: 13,
            ),
            Rule.new(
              id: 2,
              lhs: grammar.find_symbol_by_s_value!("emp"),
              rhs: [
              ],
              code: Code.new(type: :user_code, token_code: T.new(type: T::User_code, s_value: "{ $$; }")),
              nullable: true,
              precedence_sym: nil,
              lineno: 16,
            ),
            Rule.new(
              id: 3,
              lhs: grammar.find_symbol_by_s_value!("emp"),
              rhs: [
              ],
              code: Code.new(type: :user_code, token_code: T.new(type: T::User_code, s_value: "{ @$; }")),
              nullable: true,
              precedence_sym: nil,
              lineno: 18,
            ),
            Rule.new(
              id: 4,
              lhs: grammar.find_symbol_by_s_value!("emp"),
              rhs: [
              ],
              code: Code.new(type: :user_code, token_code: T.new(type: T::User_code, s_value: "{ @0; }")),
              nullable: true,
              precedence_sym: nil,
              lineno: 20,
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
