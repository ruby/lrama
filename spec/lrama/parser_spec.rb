RSpec.describe Lrama::Parser do
  T ||= Lrama::Lexer::Token
  Type = Lrama::Grammar::Type
  Sym = Lrama::Grammar::Symbol
  Precedence = Lrama::Grammar::Precedence
  Rule = Lrama::Grammar::Rule
  Printer = Lrama::Grammar::Printer
  Code = Lrama::Grammar::Code

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
      path = "common/basic.y"
      y = File.read(fixture_path(path))
      grammar = Lrama::Parser.new(y, path).parse

      expect(grammar.union.code.s_value).to eq(<<-CODE.chomp)

    int i;
    long l;
    char *str;

      CODE

      expect(grammar.expect).to eq(0)
      expect(grammar.printers).to eq([
        Printer.new(
          ident_or_tags: [T::Tag.new(s_value: "<int>")],
          token_code: T::UserCode.new(s_value: "\n    print_int();\n"),
          lineno: 15
        ),
        Printer.new(
          ident_or_tags: [T::Ident.new(s_value: "tNUMBER"), T::Ident.new(s_value: "tSTRING")],
          token_code: T::UserCode.new(s_value: "\n    print_token();\n"),
          lineno: 18
        ),
      ])
      expect(grammar.lex_param).to eq("struct lex_params *p")
      expect(grammar.parse_param).to eq("struct parse_params *p")
      expect(grammar.initial_action).to eq(Code::InitialActionCode.new(type: :initial_action, token_code: T::UserCode.new(s_value: "\n    initial_action_func(@$);\n")))
      expect(grammar.symbols.sort_by(&:number)).to match_symbols([
        Sym.new(id: T::Ident.new(s_value: "EOI"),            alias_name: "\"EOI\"",                  number:  0, tag: nil,                                   term: true, token_id:   0, nullable: false, precedence: nil,                                            printer: nil),
        Sym.new(id: T::Ident.new(s_value: "YYerror"),        alias_name: "error",                    number:  1, tag: nil,                                   term: true, token_id: 256, nullable: false, precedence: nil,                                            printer: nil),
        Sym.new(id: T::Ident.new(s_value: "YYUNDEF"),        alias_name: "\"invalid token\"",        number:  2, tag: nil,                                   term: true, token_id: 257, nullable: false, precedence: nil,                                            printer: nil),
        Sym.new(id: T::Char.new(s_value:  "'\\\\'"),         alias_name: "\"backslash\"",            number:  3, tag: T::Tag.new(s_value: "<i>"),   term: true, token_id:  92, nullable: false, precedence: nil,                                            printer: nil),
        Sym.new(id: T::Char.new(s_value:  "'\\13'"),         alias_name: "\"escaped vertical tab\"", number:  4, tag: T::Tag.new(s_value: "<i>"),   term: true, token_id:  11, nullable: false, precedence: nil,                                            printer: nil),
        Sym.new(id: T::Ident.new(s_value: "keyword_class"),  alias_name: nil,                        number:  5, tag: T::Tag.new(s_value: "<i>"),   term: true, token_id: 258, nullable: false, precedence: nil,                                            printer: nil),
        Sym.new(id: T::Ident.new(s_value: "keyword_class2"), alias_name: nil,                        number:  6, tag: T::Tag.new(s_value: "<i>"),   term: true, token_id: 259, nullable: false, precedence: nil,                                            printer: nil),
        Sym.new(id: T::Ident.new(s_value: "tNUMBER"),        alias_name: nil,                        number:  7, tag: T::Tag.new(s_value: "<l>"),   term: true, token_id: 260, nullable: false, precedence: nil,                                            printer: grammar.printers[1]),
        Sym.new(id: T::Ident.new(s_value: "tSTRING"),        alias_name: nil,                        number:  8, tag: T::Tag.new(s_value: "<str>"), term: true, token_id: 261, nullable: false, precedence: nil,                                            printer: grammar.printers[1]),
        Sym.new(id: T::Ident.new(s_value: "keyword_end"),    alias_name: "\"end\"",                  number:  9, tag: T::Tag.new(s_value: "<i>"),   term: true, token_id: 262, nullable: false, precedence: nil,                                            printer: nil),
        Sym.new(id: T::Ident.new(s_value: "tPLUS"),          alias_name: "\"+\"",                    number: 10, tag: nil,                                   term: true, token_id: 263, nullable: false, precedence: Precedence.new(type: :left,     precedence: 1), printer: nil),
        Sym.new(id: T::Ident.new(s_value: "tMINUS"),         alias_name: "\"-\"",                    number: 11, tag: nil,                                   term: true, token_id: 264, nullable: false, precedence: Precedence.new(type: :left,     precedence: 1), printer: nil),
        Sym.new(id: T::Ident.new(s_value: "tEQ"),            alias_name: "\"=\"",                    number: 12, tag: nil,                                   term: true, token_id: 265, nullable: false, precedence: Precedence.new(type: :right,    precedence: 2), printer: nil),
        Sym.new(id: T::Ident.new(s_value: "tEQEQ"),          alias_name: "\"==\"",                   number: 13, tag: nil,                                   term: true, token_id: 266, nullable: false, precedence: Precedence.new(type: :nonassoc, precedence: 0), printer: nil),
        Sym.new(id: T::Char.new(s_value:  "'>'"),            alias_name: nil,                        number: 14, tag: nil,                                   term: true, token_id:  62, nullable: false, precedence: Precedence.new(type: :left,     precedence: 1), printer: nil),
        Sym.new(id: T::Char.new(s_value:  "'+'"),            alias_name: nil,                        number: 15, tag: nil,                                   term: true, token_id:  43, nullable: false, precedence: nil,                                            printer: nil),
        Sym.new(id: T::Char.new(s_value:  "'-'"),            alias_name: nil,                        number: 16, tag: nil,                                   term: true, token_id:  45, nullable: false, precedence: nil,                                            printer: nil),
        Sym.new(id: T::Char.new(s_value:  "'!'"),            alias_name: nil,                        number: 17, tag: nil,                                   term: true, token_id:  33, nullable: false, precedence: nil,                                            printer: nil),
        Sym.new(id: T::Char.new(s_value:  "'?'"),            alias_name: nil,                        number: 18, tag: nil,                                   term: true, token_id:  63, nullable: false, precedence: nil,                                            printer: nil),

        Sym.new(id: T::Ident.new(s_value: "$accept"),   alias_name: nil, number: 19, tag: nil,                                 term: false, token_id:  0, nullable: false, precedence: nil, printer: nil),
        Sym.new(id: T::Ident.new(s_value: "program"),   alias_name: nil, number: 20, tag: nil,                                 term: false, token_id:  1, nullable: false, precedence: nil, printer: nil),
        Sym.new(id: T::Ident.new(s_value: "class"),     alias_name: nil, number: 21, tag: T::Tag.new(s_value: "<i>"), term: false, token_id:  2, nullable: false, precedence: nil, printer: nil),
        Sym.new(id: T::Ident.new(s_value: "$@1"),       alias_name: nil, number: 22, tag: nil,                                 term: false, token_id:  3, nullable:  true, precedence: nil, printer: nil),
        Sym.new(id: T::Ident.new(s_value: "$@2"),       alias_name: nil, number: 23, tag: nil,                                 term: false, token_id:  4, nullable:  true, precedence: nil, printer: nil),
        Sym.new(id: T::Ident.new(s_value: "$@3"),       alias_name: nil, number: 24, tag: nil,                                 term: false, token_id:  5, nullable:  true, precedence: nil, printer: nil),
        Sym.new(id: T::Ident.new(s_value: "$@4"),       alias_name: nil, number: 25, tag: nil,                                 term: false, token_id:  6, nullable:  true, precedence: nil, printer: nil),
        Sym.new(id: T::Ident.new(s_value: "strings_1"), alias_name: nil, number: 26, tag: nil,                                 term: false, token_id:  7, nullable: false, precedence: nil, printer: nil),
        Sym.new(id: T::Ident.new(s_value: "strings_2"), alias_name: nil, number: 27, tag: nil,                                 term: false, token_id:  8, nullable: false, precedence: nil, printer: nil),
        Sym.new(id: T::Ident.new(s_value: "string_1"),  alias_name: nil, number: 28, tag: nil,                                 term: false, token_id:  9, nullable: false, precedence: nil, printer: nil),
        Sym.new(id: T::Ident.new(s_value: "string_2"),  alias_name: nil, number: 29, tag: nil,                                 term: false, token_id: 10, nullable: false, precedence: nil, printer: nil),
        Sym.new(id: T::Ident.new(s_value: "string"),    alias_name: nil, number: 30, tag: nil,                                 term: false, token_id: 11, nullable: false, precedence: nil, printer: nil),
      ])
      expect(grammar.types).to eq([Type.new(id: T::Ident.new(s_value: "class"), tag: T::Tag.new(s_value: "<i>"))])
      _rules = grammar.rule_builders.map {|b| [b.lhs, (b.rhs + [b.precedence_sym, b.user_code]).compact, b.line] }
      expect(_rules).to eq([
        [
          T::Ident.new(s_value: "program"),
          [
            T::Ident.new(s_value: "class"),
          ],
          57,
        ],
        [
          T::Ident.new(s_value: "program"),
          [
            T::Char.new(s_value: "'+'"),
            T::Ident.new(s_value: "strings_1"),
          ],
          58,
        ],
        [
          T::Ident.new(s_value: "program"),
          [
            T::Char.new(s_value: "'-'"),
            T::Ident.new(s_value: "strings_2"),
          ],
          59,
        ],
        [
          T::Ident.new(s_value: "class"),
          [
            T::Ident.new(s_value: "keyword_class"),
            T::Ident.new(s_value: "tSTRING"),
            T::Ident.new(s_value: "keyword_end"),
            grammar.find_symbol_by_s_value!("tPLUS"),
            T::UserCode.new(s_value: " code 1 "),
          ],
          62,
        ],
        [
          T::Ident.new(s_value: "class"),
          [
            T::Ident.new(s_value: "keyword_class"),
            T::UserCode.new(s_value: " code 2 "),
            T::Ident.new(s_value: "tSTRING"),
            T::Char.new(s_value: "'!'"),
            T::Ident.new(s_value: "keyword_end"),
            T::UserCode.new(s_value: " code 3 "),
            grammar.find_symbol_by_s_value!("tEQ"),
          ],
          64,
        ],
        [
          T::Ident.new(s_value: "class"),
          [
            T::Ident.new(s_value: "keyword_class"),
            T::UserCode.new(s_value: " code 4 "),
            T::Ident.new(s_value: "tSTRING"),
            T::Char.new(s_value: "'?'"),
            T::Ident.new(s_value: "keyword_end"),
            T::UserCode.new(s_value: " code 5 "),
            grammar.find_symbol_by_s_value!("'>'"),
          ],
          65,
        ],
        [
          T::Ident.new(s_value: "strings_1"),
          [
            T::Ident.new(s_value: "string_1"),
          ],
          68,
        ],
        [
          T::Ident.new(s_value: "strings_2"),
          [
            T::Ident.new(s_value: "string_1"),
          ],
          71,
        ],
        [
          T::Ident.new(s_value: "strings_2"),
          [
            T::Ident.new(s_value: "string_2"),
          ],
          72,
        ],
        [
          T::Ident.new(s_value: "string_1"),
          [
            T::Ident.new(s_value: "string"),
          ],
          75,
        ],
        [
          T::Ident.new(s_value: "string_2"),
          [
            T::Ident.new(s_value: "string"),
            T::Char.new(s_value: "'+'"),
          ],
          78,
        ],
        [
          T::Ident.new(s_value: "string"),
          [
            T::Ident.new(s_value: "tSTRING")
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
          token_code: nil,
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
          token_code: nil,
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
          token_code: nil,
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
          token_code: nil,
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
          token_code: T::UserCode.new(s_value: " code 1 "),
          nullable: false,
          precedence_sym: grammar.find_symbol_by_s_value!("tPLUS"),
          lineno: 62,
        ),
        Rule.new(
          id: 5,
          lhs: grammar.find_symbol_by_s_value!("$@1"),
          rhs: [],
          token_code: T::UserCode.new(s_value: " code 2 "),
          position_in_original_rule_rhs: 1,
          nullable: true,
          precedence_sym: nil,
          lineno: 64,
        ),
        Rule.new(
          id: 6,
          lhs: grammar.find_symbol_by_s_value!("$@2"),
          rhs: [],
          token_code: T::UserCode.new(s_value: " code 3 "),
          position_in_original_rule_rhs: 5,
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
          token_code: nil,
          nullable: false,
          precedence_sym: grammar.find_symbol_by_s_value!("tEQ"),
          lineno: 64,
        ),
        Rule.new(
          id: 8,
          lhs: grammar.find_symbol_by_s_value!("$@3"),
          rhs: [],
          token_code: T::UserCode.new(s_value: " code 4 "),
          position_in_original_rule_rhs: 1,
          nullable: true,
          precedence_sym: nil,
          lineno: 65,
        ),
        Rule.new(
          id: 9,
          lhs: grammar.find_symbol_by_s_value!("$@4"),
          rhs: [],
          token_code: T::UserCode.new(s_value: " code 5 "),
          position_in_original_rule_rhs: 5,
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
          token_code: nil,
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
          token_code: nil,
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
          token_code: nil,
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
          token_code: nil,
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
          token_code: nil,
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
          token_code: nil,
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
          token_code: nil,
          nullable: false,
          precedence_sym: grammar.find_symbol_by_s_value!("tSTRING"),
          lineno: 81,
        ),
      ])
    end

    it "nullable" do
      path = "common/nullable.y"
      y = File.read(fixture_path(path))
      grammar = Lrama::Parser.new(y, path).parse

      expect(grammar.nterms.sort_by(&:number)).to match_symbols([
        Sym.new(id: T::Ident.new(s_value: "$accept"),       alias_name: nil, number:  6, tag: nil, term: false, token_id: 0, nullable: false),
        Sym.new(id: T::Ident.new(s_value: "program"),       alias_name: nil, number:  7, tag: nil, term: false, token_id: 1, nullable: true),
        Sym.new(id: T::Ident.new(s_value: "stmt"),          alias_name: nil, number:  8, tag: nil, term: false, token_id: 2, nullable: true),
        Sym.new(id: T::Ident.new(s_value: "expr"),          alias_name: nil, number:  9, tag: nil, term: false, token_id: 3, nullable: false),
        Sym.new(id: T::Ident.new(s_value: "opt_expr"),      alias_name: nil, number: 10, tag: nil, term: false, token_id: 4, nullable: true),
        Sym.new(id: T::Ident.new(s_value: "opt_semicolon"), alias_name: nil, number: 11, tag: nil, term: false, token_id: 5, nullable: true),
        Sym.new(id: T::Ident.new(s_value: "opt_colon"),     alias_name: nil, number: 12, tag: nil, term: false, token_id: 6, nullable: true),
      ])
      expect(grammar.rules).to eq([
        Rule.new(
          id: 0,
          lhs: grammar.find_symbol_by_s_value!("$accept"),
          rhs: [
            grammar.find_symbol_by_s_value!("program"),
            grammar.find_symbol_by_s_value!("YYEOF"),
          ],
          token_code: nil,
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
          token_code: nil,
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
          token_code: nil,
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
          token_code: nil,
          nullable: true,
          precedence_sym: nil,
          lineno: 18,
        ),
        Rule.new(
          id: 4,
          lhs: grammar.find_symbol_by_s_value!("stmt"),
          rhs: [],
          token_code: nil,
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
          token_code: nil,
          nullable: false,
          precedence_sym: grammar.find_symbol_by_s_value!("tNUMBER"),
          lineno: 22,
        ),
        Rule.new(
          id: 6,
          lhs: grammar.find_symbol_by_s_value!("opt_expr"),
          rhs: [],
          token_code: nil,
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
          token_code: nil,
          nullable: false,
          precedence_sym: nil,
          lineno: 25,
        ),
        Rule.new(
          id: 8,
          lhs: grammar.find_symbol_by_s_value!("opt_semicolon"),
          rhs: [],
          token_code: nil,
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
          token_code: nil,
          nullable: false,
          precedence_sym: grammar.find_symbol_by_s_value!("';'"),
          lineno: 29,
        ),
        Rule.new(
          id: 10,
          lhs: grammar.find_symbol_by_s_value!("opt_colon"),
          rhs: [],
          token_code: nil,
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
          token_code: nil,
          nullable: false,
          precedence_sym: grammar.find_symbol_by_s_value!("'.'"),
          lineno: 33,
        ),
      ])
    end

    context 'when parameterizing rules' do
      it "option" do
        path = "parameterizing_rules/option.y"
        y = File.read(fixture_path(path))
        grammar = Lrama::Parser.new(y, path).parse

        expect(grammar.nterms.sort_by(&:number)).to match_symbols([
          Sym.new(id: T::Ident.new(s_value: "$accept"), alias_name: nil, number: 5, tag: nil, term: false, token_id: 0, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "program"), alias_name: nil, number: 6, tag: nil, term: false, token_id: 1, nullable: true),
          Sym.new(id: T::Ident.new(s_value: "option_number"), alias_name: nil, number: 7, tag: nil, term: false, token_id: 2, nullable: true),
          Sym.new(id: T::Ident.new(s_value: "alias"), alias_name: nil, number: 8, tag: nil, term: false, token_id: 3, nullable: true),
          Sym.new(id: T::Ident.new(s_value: "option_number_alias"), alias_name: nil, number: 9, tag: nil, term: false, token_id: 4, nullable: true),
        ])

        expect(grammar.rules).to eq([
          Rule.new(
            id: 0,
            lhs: grammar.find_symbol_by_s_value!("$accept"),
            rhs: [
              grammar.find_symbol_by_s_value!("program"),
              grammar.find_symbol_by_s_value!("YYEOF"),
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("YYEOF"),
            lineno: 21,
          ),
          Rule.new(
            id: 1,
            lhs: grammar.find_symbol_by_s_value!("option_number"),
            rhs: [],
            token_code: nil,
            nullable: true,
            precedence_sym: nil,
            lineno: 21,
          ),
          Rule.new(
            id: 2,
            lhs: grammar.find_symbol_by_s_value!("option_number"),
            rhs: [
              grammar.find_symbol_by_s_value!("number"),
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("number"),
            lineno: 21,
          ),
          Rule.new(
            id: 3,
            lhs: grammar.find_symbol_by_s_value!("program"),
            rhs: [
              grammar.find_symbol_by_s_value!("option_number"),
            ],
            token_code: nil,
            nullable: true,
            precedence_sym: nil,
            lineno: 21,
          ),
          Rule.new(
            id: 4,
            lhs: grammar.find_symbol_by_s_value!("option_number_alias"),
            rhs: [],
            nullable: true,
            precedence_sym: nil,
            lineno: 24,
          ),
          Rule.new(
            id: 5,
            lhs: grammar.find_symbol_by_s_value!("option_number_alias"),
            rhs: [
              grammar.find_symbol_by_s_value!("number_alias"),
            ],
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("number_alias"),
            lineno: 24,
          ),
          Rule.new(
            id: 6,
            lhs: grammar.find_symbol_by_s_value!("alias"),
            rhs: [
              grammar.find_symbol_by_s_value!("option_number_alias"),
            ],
            nullable: true,
            precedence_sym: nil,
            lineno: 24,
          ),
        ])
      end

      it "option with whitespece before parentheses" do
        path = "parameterizing_rules/option.y"
        y = File.read(fixture_path(path))
        y.sub!('option(', 'option  (')
        grammar = Lrama::Parser.new(y, path).parse

        expect(grammar.nterms.sort_by(&:number)).to match_symbols([
          Sym.new(id: T::Ident.new(s_value: "$accept"), alias_name: nil, number: 5, tag: nil, term: false, token_id: 0, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "program"), alias_name: nil, number: 6, tag: nil, term: false, token_id: 1, nullable: true),
          Sym.new(id: T::Ident.new(s_value: "option_number"), alias_name: nil, number: 7, tag: nil, term: false, token_id: 2, nullable: true),
          Sym.new(id: T::Ident.new(s_value: "alias"), alias_name: nil, number: 8, tag: nil, term: false, token_id: 3, nullable: true),
          Sym.new(id: T::Ident.new(s_value: "option_number_alias"), alias_name: nil, number: 9, tag: nil, term: false, token_id: 4, nullable: true),
        ])

        expect(grammar.rules).to eq([
          Rule.new(
            id: 0,
            lhs: grammar.find_symbol_by_s_value!("$accept"),
            rhs: [
              grammar.find_symbol_by_s_value!("program"),
              grammar.find_symbol_by_s_value!("YYEOF"),
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("YYEOF"),
            lineno: 21,
          ),
          Rule.new(
            id: 1,
            lhs: grammar.find_symbol_by_s_value!("option_number"),
            rhs: [],
            token_code: nil,
            nullable: true,
            precedence_sym: nil,
            lineno: 21,
          ),
          Rule.new(
            id: 2,
            lhs: grammar.find_symbol_by_s_value!("option_number"),
            rhs: [
              grammar.find_symbol_by_s_value!("number"),
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("number"),
            lineno: 21,
          ),
          Rule.new(
            id: 3,
            lhs: grammar.find_symbol_by_s_value!("program"),
            rhs: [
              grammar.find_symbol_by_s_value!("option_number"),
            ],
            token_code: nil,
            nullable: true,
            precedence_sym: nil,
            lineno: 21,
          ),
          Rule.new(
            id: 4,
            lhs: grammar.find_symbol_by_s_value!("option_number_alias"),
            rhs: [],
            nullable: true,
            precedence_sym: nil,
            lineno: 24,
          ),
          Rule.new(
            id: 5,
            lhs: grammar.find_symbol_by_s_value!("option_number_alias"),
            rhs: [
              grammar.find_symbol_by_s_value!("number_alias"),
            ],
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("number_alias"),
            lineno: 24,
          ),
          Rule.new(
            id: 6,
            lhs: grammar.find_symbol_by_s_value!("alias"),
            rhs: [
              grammar.find_symbol_by_s_value!("option_number_alias"),
            ],
            nullable: true,
            precedence_sym: nil,
            lineno: 24,
          ),
        ])
      end

      it "option between rhs" do
        path = "parameterizing_rules/between_rhs.y"
        y = File.read(fixture_path(path))
        grammar = Lrama::Parser.new(y, path).parse

        expect(grammar.nterms.sort_by(&:number)).to match_symbols([
          Sym.new(id: T::Ident.new(s_value: "$accept"), alias_name: nil, number: 6, tag: nil, term: false, token_id: 0, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "program"), alias_name: nil, number: 7, tag: nil, term: false, token_id: 1, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "option_bar"), alias_name: nil, number: 8, tag: nil, term: false, token_id: 2, nullable: true),
        ])

        expect(grammar.rules).to eq([
          Rule.new(
            id: 0,
            lhs: grammar.find_symbol_by_s_value!("$accept"),
            rhs: [
              grammar.find_symbol_by_s_value!("program"),
              grammar.find_symbol_by_s_value!("YYEOF"),
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("YYEOF"),
            lineno: 22,
          ),
          Rule.new(
            id: 1,
            lhs: grammar.find_symbol_by_s_value!("option_bar"),
            rhs: [],
            token_code: nil,
            nullable: true,
            precedence_sym: nil,
            lineno: 22,
          ),
          Rule.new(
            id: 2,
            lhs: grammar.find_symbol_by_s_value!("option_bar"),
            rhs: [
              grammar.find_symbol_by_s_value!("bar")
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("bar"),
            lineno: 22,
          ),
          Rule.new(
            id: 3,
            lhs: grammar.find_symbol_by_s_value!("program"),
            rhs: [
              grammar.find_symbol_by_s_value!("foo"),
              grammar.find_symbol_by_s_value!("option_bar"),
              grammar.find_symbol_by_s_value!("baz"),
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("baz"),
            lineno: 22,
          ),
        ])
      end

      it "option with tag" do
        path = "parameterizing_rules/option_with_tag.y"
        y = File.read(fixture_path(path))
        grammar = Lrama::Parser.new(y, path).parse

        expect(grammar.nterms.sort_by(&:number)).to match_symbols([
          Sym.new(id: T::Ident.new(s_value: "$accept"), alias_name: nil, number: 5, tag: nil, term: false, token_id: 0, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "program"), alias_name: nil, number: 6, tag: nil, term: false, token_id: 1, nullable: true),
          Sym.new(id: T::Ident.new(s_value: "option_number"), alias_name: nil, number: 7, tag: T::Tag.new(s_value: "<i>"), term: false, token_id: 2, nullable: true),
          Sym.new(id: T::Ident.new(s_value: "alias"), alias_name: nil, number: 8, tag: nil, term: false, token_id: 3, nullable: true),
          Sym.new(id: T::Ident.new(s_value: "option_number_alias"), alias_name: nil, number: 9, tag: T::Tag.new(s_value: "<i>"), term: false, token_id: 4, nullable: true),
        ])

        expect(grammar.rules).to eq([
          Rule.new(
            id: 0,
            lhs: grammar.find_symbol_by_s_value!("$accept"),
            rhs: [
              grammar.find_symbol_by_s_value!("program"),
              grammar.find_symbol_by_s_value!("YYEOF"),
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("YYEOF"),
            lineno: 21,
          ),
          Rule.new(
            id: 1,
            lhs: grammar.find_symbol_by_s_value!("option_number"),
            rhs: [],
            lhs_tag: T::Tag.new(s_value: "<i>"),
            token_code: nil,
            nullable: true,
            precedence_sym: nil,
            lineno: 21,
          ),
          Rule.new(
            id: 2,
            lhs: grammar.find_symbol_by_s_value!("option_number"),
            rhs: [
              grammar.find_symbol_by_s_value!("number"),
            ],
            lhs_tag: T::Tag.new(s_value: "<i>"),
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("number"),
            lineno: 21,
          ),
          Rule.new(
            id: 3,
            lhs: grammar.find_symbol_by_s_value!("program"),
            rhs: [
              grammar.find_symbol_by_s_value!("option_number"),
            ],
            token_code: nil,
            nullable: true,
            precedence_sym: nil,
            lineno: 21,
          ),
          Rule.new(
            id: 4,
            lhs: grammar.find_symbol_by_s_value!("option_number_alias"),
            rhs: [],
            lhs_tag: T::Tag.new(s_value: "<i>"),
            nullable: true,
            precedence_sym: nil,
            lineno: 24,
          ),
          Rule.new(
            id: 5,
            lhs: grammar.find_symbol_by_s_value!("option_number_alias"),
            rhs: [
              grammar.find_symbol_by_s_value!("number_alias"),
            ],
            lhs_tag: T::Tag.new(s_value: "<i>"),
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("number_alias"),
            lineno: 24,
          ),
          Rule.new(
            id: 6,
            lhs: grammar.find_symbol_by_s_value!("alias"),
            rhs: [
              grammar.find_symbol_by_s_value!("option_number_alias"),
            ],
            nullable: true,
            precedence_sym: nil,
            lineno: 24,
          ),
        ])
      end

      it "nonempty list" do
        path = "parameterizing_rules/nonempty_list.y"
        y = File.read(fixture_path(path))
        grammar = Lrama::Parser.new(y, path).parse

        expect(grammar.nterms.sort_by(&:number)).to match_symbols([
          Sym.new(id: T::Ident.new(s_value: "$accept"), alias_name: nil, number: 5, tag: nil, term: false, token_id: 0, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "program"), alias_name: nil, number: 6, tag: nil, term: false, token_id: 1, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "nonempty_list_number"), alias_name: nil, number: 7, tag: nil, term: false, token_id: 2, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "alias"), alias_name: nil, number: 8, tag: nil, term: false, token_id: 3, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "nonempty_list_number_alias"), alias_name: nil, number: 9, tag: nil, term: false, token_id: 4, nullable: false),
        ])

        expect(grammar.rules).to eq([
          Rule.new(
            id: 0,
            lhs: grammar.find_symbol_by_s_value!("$accept"),
            rhs: [
              grammar.find_symbol_by_s_value!("program"),
              grammar.find_symbol_by_s_value!("YYEOF"),
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("YYEOF"),
            lineno: 21,
          ),
          Rule.new(
            id: 1,
            lhs: grammar.find_symbol_by_s_value!("nonempty_list_number"),
            rhs: [
              grammar.find_symbol_by_s_value!("number"),
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("number"),
            lineno: 21,
          ),
          Rule.new(
            id: 2,
            lhs: grammar.find_symbol_by_s_value!("nonempty_list_number"),
            rhs: [
              grammar.find_symbol_by_s_value!("nonempty_list_number"),
              grammar.find_symbol_by_s_value!("number"),
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("number"),
            lineno: 21,
          ),
          Rule.new(
            id: 3,
            lhs: grammar.find_symbol_by_s_value!("program"),
            rhs: [
              grammar.find_symbol_by_s_value!("nonempty_list_number"),
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: nil,
            lineno: 21,
          ),
          Rule.new(
            id: 4,
            lhs: grammar.find_symbol_by_s_value!("nonempty_list_number_alias"),
            rhs: [
              grammar.find_symbol_by_s_value!("number_alias"),
            ],
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("number_alias"),
            lineno: 24,
          ),
          Rule.new(
            id: 5,
            lhs: grammar.find_symbol_by_s_value!("nonempty_list_number_alias"),
            rhs: [
              grammar.find_symbol_by_s_value!("nonempty_list_number_alias"),
              grammar.find_symbol_by_s_value!("number_alias"),
            ],
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("number_alias"),
            lineno: 24,
          ),
          Rule.new(
            id: 6,
            lhs: grammar.find_symbol_by_s_value!("alias"),
            rhs: [
              grammar.find_symbol_by_s_value!("nonempty_list_number_alias"),
            ],
            nullable: false,
            precedence_sym: nil,
            lineno: 24,
          ),
        ])
      end

      it "list" do
        path = "parameterizing_rules/list.y"
        y = File.read(fixture_path(path))
        grammar = Lrama::Parser.new(y, path).parse

        expect(grammar.nterms.sort_by(&:number)).to match_symbols([
          Sym.new(id: T::Ident.new(s_value: "$accept"), alias_name: nil, number: 5, tag: nil, term: false, token_id: 0, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "program"), alias_name: nil, number: 6, tag: nil, term: false, token_id: 1, nullable: true),
          Sym.new(id: T::Ident.new(s_value: "list_number"), alias_name: nil, number: 7, tag: nil, term: false, token_id: 2, nullable: true),
          Sym.new(id: T::Ident.new(s_value: "alias"), alias_name: nil, number: 8, tag: nil, term: false, token_id: 3, nullable: true),
          Sym.new(id: T::Ident.new(s_value: "list_number_alias"), alias_name: nil, number: 9, tag: nil, term: false, token_id: 4, nullable: true),
        ])

        expect(grammar.rules).to eq([
          Rule.new(
            id: 0,
            lhs: grammar.find_symbol_by_s_value!("$accept"),
            rhs: [
              grammar.find_symbol_by_s_value!("program"),
              grammar.find_symbol_by_s_value!("YYEOF"),
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("YYEOF"),
            lineno: 21,
          ),
          Rule.new(
            id: 1,
            lhs: grammar.find_symbol_by_s_value!("list_number"),
            rhs: [],
            token_code: nil,
            nullable: true,
            precedence_sym: nil,
            lineno: 21,
          ),
          Rule.new(
            id: 2,
            lhs: grammar.find_symbol_by_s_value!("list_number"),
            rhs: [
              grammar.find_symbol_by_s_value!("list_number"),
              grammar.find_symbol_by_s_value!("number"),
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("number"),
            lineno: 21,
          ),
          Rule.new(
            id: 3,
            lhs: grammar.find_symbol_by_s_value!("program"),
            rhs: [
              grammar.find_symbol_by_s_value!("list_number"),
            ],
            token_code: nil,
            nullable: true,
            precedence_sym: nil,
            lineno: 21,
          ),
          Rule.new(
            id: 4,
            lhs: grammar.find_symbol_by_s_value!("list_number_alias"),
            rhs: [],
            nullable: true,
            precedence_sym: nil,
            lineno: 24,
          ),
          Rule.new(
            id: 5,
            lhs: grammar.find_symbol_by_s_value!("list_number_alias"),
            rhs: [
              grammar.find_symbol_by_s_value!("list_number_alias"),
              grammar.find_symbol_by_s_value!("number_alias"),
            ],
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("number_alias"),
            lineno: 24,
          ),
          Rule.new(
            id: 6,
            lhs: grammar.find_symbol_by_s_value!("alias"),
            rhs: [
              grammar.find_symbol_by_s_value!("list_number_alias"),
            ],
            nullable: true,
            precedence_sym: nil,
            lineno: 24,
          ),
        ])
      end

      it "separated_nonempty_list" do
        path = "parameterizing_rules/separated_nonempty_list.y"
        y = File.read(fixture_path(path))
        grammar = Lrama::Parser.new(y, path).parse

        expect(grammar.nterms.sort_by(&:number)).to match_symbols([
          Sym.new(id: T::Ident.new(s_value: "$accept"), alias_name: nil, number:  5, tag: nil, term: false, token_id: 0, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "program"), alias_name: nil, number:  6, tag: nil, term: false, token_id: 1, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "separated_nonempty_list_number"), alias_name: nil, number:  7, tag: nil, term: false, token_id: 2, nullable: false),
        ])

        expect(grammar.rules).to eq([
          Rule.new(
            id: 0,
            lhs: grammar.find_symbol_by_s_value!("$accept"),
            rhs: [
              grammar.find_symbol_by_s_value!("program"),
              grammar.find_symbol_by_s_value!("YYEOF"),
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("YYEOF"),
            lineno: 20,
          ),
          Rule.new(
            id: 1,
            lhs: grammar.find_symbol_by_s_value!("separated_nonempty_list_number"),
            rhs: [
              grammar.find_symbol_by_s_value!("number"),
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("number"),
            lineno: 20,
          ),
          Rule.new(
            id: 2,
            lhs: grammar.find_symbol_by_s_value!("separated_nonempty_list_number"),
            rhs: [
              grammar.find_symbol_by_s_value!("separated_nonempty_list_number"),
              grammar.find_symbol_by_number!(4),
              grammar.find_symbol_by_s_value!("number"),
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("number"),
            lineno: 20,
          ),
          Rule.new(
            id: 3,
            lhs: grammar.find_symbol_by_s_value!("program"),
            rhs: [
              grammar.find_symbol_by_s_value!("separated_nonempty_list_number"),
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: nil,
            lineno: 20,
          ),
        ])
      end

      it "separated_list" do
        path = "parameterizing_rules/separated_list.y"
        y = File.read(fixture_path(path))
        grammar = Lrama::Parser.new(y, path).parse

        expect(grammar.nterms.sort_by(&:number)).to match_symbols([
          Sym.new(id: T::Ident.new(s_value: "$accept"), alias_name: nil, number:  5, tag: nil, term: false, token_id: 0, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "program"), alias_name: nil, number:  6, tag: nil, term: false, token_id: 1, nullable: true),
          Sym.new(id: T::Ident.new(s_value: "separated_list_number"), alias_name: nil, number:  7, tag: nil, term: false, token_id: 2, nullable: true),
          Sym.new(id: T::Ident.new(s_value: "separated_nonempty_list_number"), alias_name: nil, number:  8, tag: nil, term: false, token_id: 3, nullable: false),
        ])

        expect(grammar.rules).to eq([
          Rule.new(
            id: 0,
            lhs: grammar.find_symbol_by_s_value!("$accept"),
            rhs: [
              grammar.find_symbol_by_s_value!("program"),
              grammar.find_symbol_by_s_value!("YYEOF"),
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("YYEOF"),
            lineno: 20,
          ),
          Rule.new(
            id: 1,
            lhs: grammar.find_symbol_by_s_value!("separated_list_number"),
            rhs: [],
            token_code: nil,
            nullable: true,
            precedence_sym: nil,
            lineno: 20,
          ),
          Rule.new(
            id: 2,
            lhs: grammar.find_symbol_by_s_value!("separated_list_number"),
            rhs: [
              grammar.find_symbol_by_s_value!("separated_nonempty_list_number"),
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: nil,
            lineno: 20,
          ),
          Rule.new(
            id: 3,
            lhs: grammar.find_symbol_by_s_value!("separated_nonempty_list_number"),
            rhs: [
              grammar.find_symbol_by_s_value!("number")
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("number"),
            lineno: 20,
          ),
          Rule.new(
            id: 4,
            lhs: grammar.find_symbol_by_s_value!("separated_nonempty_list_number"),
            rhs: [
              grammar.find_symbol_by_s_value!("separated_nonempty_list_number"),
              grammar.find_symbol_by_number!(4),
              grammar.find_symbol_by_s_value!("number"),
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("number"),
            lineno: 20,
          ),
          Rule.new(
            id: 5,
            lhs: grammar.find_symbol_by_s_value!("program"),
            rhs: [
              grammar.find_symbol_by_s_value!("separated_list_number"),
            ],
            token_code: nil,
            nullable: true,
            precedence_sym: nil,
            lineno: 20,
          ),
        ])
      end

      it "user defined" do
        path = "parameterizing_rules/user_defined.y"
        y = File.read(fixture_path(path))
        grammar = Lrama::Parser.new(y, path).parse

        expect(grammar.nterms.sort_by(&:number)).to match_symbols([
          Sym.new(id: T::Ident.new(s_value: "$accept"), alias_name: nil, number: 6, tag: nil, term: false, token_id: 0, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "program"), alias_name: nil, number: 7, tag: nil, term: false, token_id: 1, nullable: true),
          Sym.new(id: T::Ident.new(s_value: "defined_option_number"), alias_name: nil, number: 8, tag: T::Tag.new(s_value: "<i>"), term: false, token_id: 2, nullable: true),
          Sym.new(id: T::Ident.new(s_value: "multi_args_number_string"), alias_name: nil, number: 9, tag: nil, term: false, token_id: 3, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "multi_args_number_number"), alias_name: nil, number: 10, tag: nil, term: false, token_id: 4, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "pair_number_string"), alias_name: nil, number: 11, tag: nil, term: false, token_id: 5, nullable: false),
        ])

        expect(grammar.rules).to eq([
          Rule.new(
            id: 0,
            lhs: grammar.find_symbol_by_s_value!("$accept"),
            rhs: [
              grammar.find_symbol_by_s_value!("program"),
              grammar.find_symbol_by_s_value!("YYEOF"),
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("YYEOF"),
            lineno: 36,
          ),
          Rule.new(
            id: 1,
            lhs: grammar.find_symbol_by_s_value!("defined_option_number"),
            rhs: [],
            lhs_tag: T::Tag.new(s_value: "<i>"),
            token_code: nil,
            nullable: true,
            precedence_sym: nil,
            lineno: 36,
          ),
          Rule.new(
            id: 2,
            lhs: grammar.find_symbol_by_s_value!("defined_option_number"),
            rhs: [
              grammar.find_symbol_by_s_value!("number"),
            ],
            lhs_tag: T::Tag.new(s_value: "<i>"),
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("number"),
            lineno: 36,
          ),
          Rule.new(
            id: 3,
            lhs: grammar.find_symbol_by_s_value!("program"),
            rhs: [
              grammar.find_symbol_by_s_value!("defined_option_number"),
            ],
            token_code: nil,
            nullable: true,
            precedence_sym: nil,
            lineno: 36,
          ),
          Rule.new(
            id: 4,
            lhs: grammar.find_symbol_by_s_value!("multi_args_number_string"),
            rhs: [
              grammar.find_symbol_by_s_value!("number"),
            ],
            lhs_tag: nil,
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("number"),
            lineno: 37,
          ),
          Rule.new(
            id: 5,
            lhs: grammar.find_symbol_by_s_value!("multi_args_number_string"),
            rhs: [
              grammar.find_symbol_by_s_value!("string"),
            ],
            lhs_tag: nil,
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("string"),
            lineno: 37,
          ),
          Rule.new(
            id: 6,
            lhs: grammar.find_symbol_by_s_value!("program"),
            rhs: [
              grammar.find_symbol_by_s_value!("multi_args_number_string"),
            ],
            lhs_tag: nil,
            token_code: nil,
            nullable: false,
            precedence_sym: nil,
            lineno: 37,
          ),
          Rule.new(
            id: 7,
            lhs: grammar.find_symbol_by_s_value!("multi_args_number_number"),
            rhs: [
              grammar.find_symbol_by_s_value!("number"),
            ],
            lhs_tag: nil,
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("number"),
            lineno: 38,
          ),
          Rule.new(
            id: 8,
            lhs: grammar.find_symbol_by_s_value!("multi_args_number_number"),
            rhs: [
              grammar.find_symbol_by_s_value!("number"),
            ],
            lhs_tag: nil,
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("number"),
            lineno: 38,
          ),
          Rule.new(
            id: 9,
            lhs: grammar.find_symbol_by_s_value!("program"),
            rhs: [
              grammar.find_symbol_by_s_value!("multi_args_number_number"),
            ],
            lhs_tag: nil,
            token_code: nil,
            nullable: false,
            precedence_sym: nil,
            lineno: 38,
          ),
          Rule.new(
            id: 10,
            lhs: grammar.find_symbol_by_s_value!("pair_number_string"),
            rhs: [
              grammar.find_symbol_by_s_value!("number"),
              grammar.find_symbol_by_number!(5),
              grammar.find_symbol_by_s_value!("string"),
            ],
            lhs_tag: nil,
            token_code: T::UserCode.new(s_value: " printf(\"(%d, %d)\\n\", $1, $2); "),
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("string"),
            lineno: 39,
          ),
          Rule.new(
            id: 11,
            lhs: grammar.find_symbol_by_s_value!("program"),
            rhs: [
              grammar.find_symbol_by_s_value!("pair_number_string"),
            ],
            lhs_tag: nil,
            token_code: T::UserCode.new(s_value: " printf(\"pair odd even\\n\"); "),
            nullable: false,
            precedence_sym: nil,
            lineno: 39,
          ),
        ])
      end

      it "user defined with nest" do
        path = "parameterizing_rules/user_defined_with_nest.y"
        y = File.read(fixture_path(path))
        grammar = Lrama::Parser.new(y, path).parse

        expect(grammar.nterms.sort_by(&:number)).to match_symbols([
          Sym.new(id: T::Ident.new(s_value: "$accept"), alias_name: nil, number: 5, tag: nil, term: false, token_id: 0, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "program"), alias_name: nil, number: 6, tag: nil, term: false, token_id: 1, nullable: true),
          Sym.new(id: T::Ident.new(s_value: "option_number"), alias_name: nil, number: 7, tag: nil, term: false, token_id: 2, nullable: true),
          Sym.new(id: T::Ident.new(s_value: "nested_option_number"), alias_name: nil, number: 8, tag: nil, term: false, token_id: 3, nullable: true),
          Sym.new(id: T::Ident.new(s_value: "nested_nested_option_number"), alias_name: nil, number: 9, tag: nil, term: false, token_id: 4, nullable: true),
          Sym.new(id: T::Ident.new(s_value: "multi_option_number_string"), alias_name: nil, number: 10, tag: nil, term: false, token_id: 5, nullable: true),
          Sym.new(id: T::Ident.new(s_value: "nested_multi_option_number"), alias_name: nil, number: 11, tag: nil, term: false, token_id: 6, nullable: true),
          Sym.new(id: T::Ident.new(s_value: "nested_multi_option_string"), alias_name: nil, number: 12, tag: nil, term: false, token_id: 7, nullable: true)
        ])

        expect(grammar.rules).to eq([
          Rule.new(
            id: 0,
            lhs: grammar.find_symbol_by_s_value!("$accept"),
            rhs: [
              grammar.find_symbol_by_s_value!("program"),
              grammar.find_symbol_by_s_value!("YYEOF"),
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("YYEOF"),
            lineno: 42,
          ),
          Rule.new(
            id: 1,
            lhs: grammar.find_symbol_by_s_value!("option_number"),
            rhs: [],
            token_code: nil,
            nullable: true,
            precedence_sym: nil,
            lineno: 42,
          ),
          Rule.new(
            id: 2,
            lhs: grammar.find_symbol_by_s_value!("nested_option_number"),
            rhs: [],
            token_code: nil,
            nullable: true,
            precedence_sym: nil,
            lineno: 42,
          ),
          Rule.new(
            id: 3,
            lhs: grammar.find_symbol_by_s_value!("nested_nested_option_number"),
            rhs: [],
            token_code: nil,
            nullable: true,
            precedence_sym: nil,
            lineno: 42,
          ),
          Rule.new(
            id: 4,
            lhs: grammar.find_symbol_by_s_value!("nested_nested_option_number"),
            rhs: [
              grammar.find_symbol_by_s_value!("number")
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("number"),
            lineno: 42,
          ),
          Rule.new(
            id: 5,
            lhs: grammar.find_symbol_by_s_value!("nested_option_number"),
            rhs: [
              grammar.find_symbol_by_s_value!("nested_nested_option_number")
            ],
            token_code: nil,
            nullable: true,
            precedence_sym: nil,
            lineno: 42,
          ),
          Rule.new(
            id: 6,
            lhs: grammar.find_symbol_by_s_value!("option_number"),
            rhs: [
              grammar.find_symbol_by_s_value!("nested_option_number")
            ],
            token_code: nil,
            nullable: true,
            precedence_sym: nil,
            lineno: 42,
          ),
          Rule.new(
            id: 7,
            lhs: grammar.find_symbol_by_s_value!("program"),
            rhs: [
              grammar.find_symbol_by_s_value!("option_number")
            ],
            token_code: nil,
            nullable: true,
            precedence_sym: nil,
            lineno: 42,
          ),
          Rule.new(
            id: 8,
            lhs: grammar.find_symbol_by_s_value!("multi_option_number_string"),
            rhs: [],
            token_code: nil,
            nullable: true,
            precedence_sym: nil,
            lineno: 43,
          ),
          Rule.new(
            id: 9,
            lhs: grammar.find_symbol_by_s_value!("nested_multi_option_number"),
            rhs: [],
            token_code: nil,
            nullable: true,
            precedence_sym: nil,
            lineno: 43,
          ),
          Rule.new(
            id: 10,
            lhs: grammar.find_symbol_by_s_value!("nested_multi_option_number"),
            rhs: [
              grammar.find_symbol_by_s_value!("number")
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("number"),
            lineno: 43,
          ),
          Rule.new(
            id: 11,
            lhs: grammar.find_symbol_by_s_value!("multi_option_number_string"),
            rhs: [
              grammar.find_symbol_by_s_value!("nested_multi_option_number")
            ],
            token_code: nil,
            nullable: true,
            precedence_sym: nil,
            lineno: 43,
          ),
          Rule.new(
            id: 12,
            lhs: grammar.find_symbol_by_s_value!("nested_multi_option_string"),
            rhs: [],
            token_code: nil,
            nullable: true,
            precedence_sym: nil,
            lineno: 43,
          ),
          Rule.new(
            id: 13,
            lhs: grammar.find_symbol_by_s_value!("nested_multi_option_string"),
            rhs: [
              grammar.find_symbol_by_s_value!("string")
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("string"),
            lineno: 43,
          ),
          Rule.new(
            id: 14,
            lhs: grammar.find_symbol_by_s_value!("multi_option_number_string"),
            rhs: [
              grammar.find_symbol_by_s_value!("nested_multi_option_string"),
              grammar.find_symbol_by_s_value!("number")
            ],
            token_code: nil,
            nullable: false,
            precedence_sym: grammar.find_symbol_by_s_value!("number"),
            lineno: 43,
          ),
          Rule.new(
            id: 15,
            lhs: grammar.find_symbol_by_s_value!("program"),
            rhs: [
              grammar.find_symbol_by_s_value!("multi_option_number_string")
            ],
            token_code: nil,
            nullable: true,
            precedence_sym: nil,
            lineno: 43,
          ),
        ])
      end

      context 'when error case' do
        context "when invalid argument number" do
          it "raise an error" do
            path = "parameterizing_rules/invalid_argument_number.y"
            y = File.read(fixture_path(path))
            expect { Lrama::Parser.new(y, path).parse }.to raise_error(/Invalid number of arguments\. expect: 1 actual: 2/)
          end
        end

        context "when invalid rule name" do
          it "raise an error" do
            path = "parameterizing_rules/invalid_rule_name.y"
            y = File.read(fixture_path(path))
            expect { Lrama::Parser.new(y, path).parse }.to raise_error(/Parameterizing rule does not exist\. `invalid`/)
          end
        end
      end
    end

    it "; for rules is optional" do
      y = header + <<~INPUT
%%

program: class

class : keyword_class tSTRING keyword_end { code 1 }
      | error

%%
      INPUT

      grammar = Lrama::Parser.new(y, "parse.y").parse

      _rules = grammar.rule_builders.map {|b| [b.lhs, (b.rhs + [b.precedence_sym, b.user_code]).compact, b.line] }
      expect(_rules).to eq([
        [
          T::Ident.new(s_value: "program"),
          [
            T::Ident.new(s_value: "class")
          ],
          29,
        ],
        [
          T::Ident.new(s_value: "class"),
          [
            T::Ident.new(s_value: "keyword_class"),
            T::Ident.new(s_value: "tSTRING"),
            T::Ident.new(s_value: "keyword_end"),
            T::UserCode.new(s_value: " code 1 "),
          ],
          31,
        ],
        [
          T::Ident.new(s_value: "class"),
          [
            T::Ident.new(s_value: "error")
          ],
          32,
        ],
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
      grammar = Lrama::Parser.new(y, "parse.y").parse

      expect(grammar.terms.sort_by(&:number)).to match_symbols([
        Sym.new(id: T::Ident.new(s_value: "EOI"),           alias_name: "\"EOI\"",           number:  0, tag: nil,                                   term: true, token_id:   0, nullable: false, precedence: nil),
        Sym.new(id: T::Ident.new(s_value: "YYerror"),       alias_name: "error",             number:  1, tag: nil,                                   term: true, token_id: 256, nullable: false, precedence: nil),
        Sym.new(id: T::Ident.new(s_value: "YYUNDEF"),       alias_name: "\"invalid token\"", number:  2, tag: nil,                                   term: true, token_id: 257, nullable: false, precedence: nil),
        Sym.new(id: T::Ident.new(s_value: "keyword_class"), alias_name: nil,                 number:  3, tag: T::Tag.new(s_value: "<i>"),   term: true, token_id: 258, nullable: false, precedence: nil),
        Sym.new(id: T::Ident.new(s_value: "tNUMBER"),       alias_name: nil,                 number:  4, tag: T::Tag.new(s_value: "<l>"),   term: true, token_id: 259, nullable: false, precedence: nil),
        Sym.new(id: T::Ident.new(s_value: "tSTRING"),       alias_name: nil,                 number:  5, tag: T::Tag.new(s_value: "<str>"), term: true, token_id: 260, nullable: false, precedence: nil),
        Sym.new(id: T::Ident.new(s_value: "keyword_end"),   alias_name: "\"end\"",           number:  6, tag: T::Tag.new(s_value: "<i>"),   term: true, token_id: 261, nullable: false, precedence: nil),
        Sym.new(id: T::Ident.new(s_value: "tPLUS"),         alias_name: "\"+\"",             number:  7, tag: nil,                                   term: true, token_id: 262, nullable: false, precedence: Precedence.new(type: :left,     precedence: 1)),
        Sym.new(id: T::Ident.new(s_value: "tMINUS"),        alias_name: "\"-\"",             number:  8, tag: nil,                                   term: true, token_id: 263, nullable: false, precedence: Precedence.new(type: :left,     precedence: 1)),
        Sym.new(id: T::Ident.new(s_value: "tEQ"),           alias_name: "\"=\"",             number:  9, tag: nil,                                   term: true, token_id: 264, nullable: false, precedence: Precedence.new(type: :right,    precedence: 2)),
        Sym.new(id: T::Ident.new(s_value: "tEQEQ"),         alias_name: "\"==\"",            number: 10, tag: nil,                                   term: true, token_id: 265, nullable: false, precedence: Precedence.new(type: :nonassoc, precedence: 0)),
      ])
      _rules = grammar.rule_builders.map {|b| [b.lhs, (b.rhs + [b.precedence_sym, b.user_code]).compact, b.line] }
      expect(_rules).to eq([
        [
          T::Ident.new(s_value: "program"),
          [
            T::Ident.new(s_value: "class")
          ],
          29,
        ],
        [
          T::Ident.new(s_value: "class"),
          [
            T::Ident.new(s_value: "keyword_class"),
            T::Ident.new(s_value: "tSTRING"),
            T::Ident.new(s_value: "keyword_end"),
            T::UserCode.new(s_value: " code 1 "),
          ],
          31,
        ],
        [
          T::Ident.new(s_value: "class"),
          [
            T::Ident.new(s_value: "error")
          ],
          32,
        ],
      ])
    end

    it "action in the middle of RHS" do
      y = header + <<~INPUT
%%

program: class ;

class : keyword_class { code 1 } tSTRING { code 2 } keyword_end { code 3 }
      | keyword_class tSTRING keyword_end { code 4 }
      ;

%%

      INPUT
      grammar = Lrama::Parser.new(y, "parse.y").parse

      expect(grammar.nterms.sort_by(&:number)).to match_symbols([
        Sym.new(id: T::Ident.new(s_value: "$accept"), alias_name: nil, number: 11, tag: nil,                                 term: false, token_id: 0, nullable: false),
        Sym.new(id: T::Ident.new(s_value: "program"), alias_name: nil, number: 12, tag: nil,                                 term: false, token_id: 1, nullable: false),
        Sym.new(id: T::Ident.new(s_value: "class"),   alias_name: nil, number: 13, tag: T::Tag.new(s_value: "<i>"), term: false, token_id: 2, nullable: false),
        Sym.new(id: T::Ident.new(s_value: "$@1"),     alias_name: nil, number: 14, tag: nil,                                 term: false, token_id: 3, nullable: true),
        Sym.new(id: T::Ident.new(s_value: "$@2"),     alias_name: nil, number: 15, tag: nil,                                 term: false, token_id: 4, nullable: true),
      ])
      expect(grammar.rules).to eq([
        Rule.new(
          id: 0,
          lhs: grammar.find_symbol_by_s_value!("$accept"),
          rhs: [
            grammar.find_symbol_by_s_value!("program"),
            grammar.find_symbol_by_s_value!("EOI"),
          ],
          token_code: nil,
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
          token_code: nil,
          nullable: false,
          precedence_sym: nil,
          lineno: 29,
        ),
        Rule.new(
          id: 2,
          lhs: grammar.find_symbol_by_s_value!("$@1"),
          rhs: [],
          token_code: T::UserCode.new(s_value: " code 1 "),
          position_in_original_rule_rhs: 1,
          nullable: true,
          precedence_sym: nil,
          lineno: 31,
        ),
        Rule.new(
          id: 3,
          lhs: grammar.find_symbol_by_s_value!("$@2"),
          rhs: [],
          token_code: T::UserCode.new(s_value: " code 2 "),
          position_in_original_rule_rhs: 3,
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
          token_code: T::UserCode.new(s_value: " code 3 "),
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
          token_code: T::UserCode.new(s_value: " code 4 "),
          nullable: false,
          precedence_sym: grammar.find_symbol_by_s_value!("keyword_end"),
          lineno: 32,
        ),
      ])
    end

    describe "invalid_prec" do
      it "raises error if ident exists after %prec" do
        y = header + <<~INPUT
%%

program: class ;

class : keyword_class tSTRING %prec tPLUS keyword_end { code 1 }
      ;

%%

        INPUT
        parser = Lrama::Parser.new(y, "parse.y")

        expect { parser.parse }.to raise_error(ParseError, <<~ERROR)
          parse.y:31: ident after %prec
          class : keyword_class tSTRING %prec tPLUS keyword_end { code 1 }
                                                    ^^^^^^^^^^^
        ERROR
      end

      it "raises error if char exists after %prec" do
        y = header + <<~INPUT
%%

program: class ;

class : keyword_class { code 2 } tSTRING %prec "=" '!' keyword_end { code 3 }
      ;

%%

        INPUT
        parser = Lrama::Parser.new(y, "parse.y")

        expect { parser.parse }.to raise_error(ParseError, <<~ERROR)
          parse.y:31: char after %prec
          class : keyword_class { code 2 } tSTRING %prec "=" '!' keyword_end { code 3 }
                                                             ^^^
        ERROR
      end

      it "raises error if code exists after %prec" do
        y = header + <<~INPUT
%%

program: class ;

class : keyword_class { code 4 } tSTRING '?' keyword_end %prec tEQ { code 5 } { code 6 }
      ;

%%

        INPUT
        parser = Lrama::Parser.new(y, "parse.y")

        expect { parser.parse }.to raise_error(ParseError, <<~ERROR)
          parse.y:31: multiple User_code after %prec
          class : keyword_class { code 4 } tSTRING '?' keyword_end %prec tEQ { code 5 } { code 6 }
                                                                                        ^
        ERROR
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
        grammar = Lrama::Parser.new(y, "parse.y").parse
        codes = grammar.rules.map(&:token_code).compact

        expect(codes.count).to eq(1)
        expect(codes[0].s_value).to eq(<<-STR.chomp)

            func("}");
        
        STR
      end
    end

    describe "' in user code" do
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
        grammar = Lrama::Parser.new(y, "parse.y").parse
        codes = grammar.rules.map(&:token_code).compact

        expect(codes.count).to eq(1)
        expect(codes[0].s_value).to eq(<<-STR.chomp)

            func('}');
        
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
        grammar = Lrama::Parser.new(y, "parse.y").parse

        expect(grammar.terms.sort_by(&:number)).to match_symbols([
          Sym.new(id: T::Ident.new(s_value: "EOI"),           alias_name: "\"EOI\"",           number:  0, tag: nil,                                   term: true, token_id:   0, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "YYerror"),       alias_name: "error",             number:  1, tag: nil,                                   term: true, token_id: 256, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "YYUNDEF"),       alias_name: "\"invalid token\"", number:  2, tag: nil,                                   term: true, token_id: 257, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "keyword_class"), alias_name: nil,                 number:  3, tag: T::Tag.new(s_value: "<i>"),   term: true, token_id: 258, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "tNUMBER"),       alias_name: nil,                 number:  4, tag: T::Tag.new(s_value: "<l>"),   term: true, token_id:   6, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "tSTRING"),       alias_name: nil,                 number:  5, tag: T::Tag.new(s_value: "<str>"), term: true, token_id: 259, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "keyword_end"),   alias_name: "\"end\"",           number:  6, tag: T::Tag.new(s_value: "<i>"),   term: true, token_id: 260, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "tPLUS"),         alias_name: "\"+\"",             number:  7, tag: nil,                                   term: true, token_id: 261, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "tMINUS"),        alias_name: "\"-\"",             number:  8, tag: nil,                                   term: true, token_id: 262, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "tEQ"),           alias_name: "\"=\"",             number:  9, tag: nil,                                   term: true, token_id: 263, nullable: false),
          Sym.new(id: T::Ident.new(s_value: "tEQEQ"),         alias_name: "\"==\"",            number: 10, tag: nil,                                   term: true, token_id: 264, nullable: false),
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
        grammar = Lrama::Parser.new(y, "parse.y").parse

        expect(grammar.terms.sort_by(&:number)).to match_symbols([
          Sym.new(id: T::Ident.new(s_value: "EOI"),           alias_name: "\"EOI\"",           number: 0, tag: nil,                                   term: true, token_id:   0, nullable: false, precedence: nil),
          Sym.new(id: T::Ident.new(s_value: "YYerror"),       alias_name: "error",             number: 1, tag: nil,                                   term: true, token_id: 256, nullable: false, precedence: nil),
          Sym.new(id: T::Ident.new(s_value: "YYUNDEF"),       alias_name: "\"invalid token\"", number: 2, tag: nil,                                   term: true, token_id: 257, nullable: false, precedence: nil),
          Sym.new(id: T::Ident.new(s_value: "keyword_class"), alias_name: nil,                 number: 3, tag: T::Tag.new(s_value: "<i>"),   term: true, token_id: 258, nullable: false, precedence: nil),
          Sym.new(id: T::Ident.new(s_value: "tSTRING"),       alias_name: nil,                 number: 4, tag: T::Tag.new(s_value: "<str>"), term: true, token_id: 259, nullable: false, precedence: nil),
          Sym.new(id: T::Ident.new(s_value: "keyword_end"),   alias_name: "\"end\"",           number: 5, tag: T::Tag.new(s_value: "<i>"),   term: true, token_id: 260, nullable: false, precedence: nil),
          Sym.new(id: T::Ident.new(s_value: "tEQ"),           alias_name: "\"=\"",             number: 6, tag: nil,                                   term: true, token_id: 261, nullable: false, precedence: nil),
          Sym.new(id: T::Char.new(s_value:  "'&'"),           alias_name: nil,                 number: 7, tag: nil,                                   term: true, token_id:  38, nullable: false, precedence: Precedence.new(type: :left, precedence: 0)),
          Sym.new(id: T::Ident.new(s_value: "tEQEQ"),         alias_name: "\"==\"",            number: 8, tag: nil,                                   term: true, token_id: 262, nullable: false, precedence: nil),
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
          { $<i>1 = 1; $<i>$ = 2; }
          { $<i>$ = 3; }
          { $<i>$ = 4; }
        tARGS
          { 5; }
        tBODY
          { $<i>2; $<i>3; $<i>5; $<i>7; $<i>$ = 1; }
        ;
%%
          INPUT
          grammar = Lrama::Parser.new(y, "parse.y").parse

          expect(grammar.rules).to eq([
            Rule.new(
              id: 0,
              lhs: grammar.find_symbol_by_s_value!("$accept"),
              rhs: [
                grammar.find_symbol_by_s_value!("program"),
                grammar.find_symbol_by_s_value!("EOI"),
              ],
              token_code: nil,
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
              token_code: nil,
              nullable: false,
              precedence_sym: nil,
              lineno: 14,
            ),
            Rule.new(
              id: 2,
              lhs: grammar.find_symbol_by_s_value!("@1"),
              rhs: [],
              token_code: T::UserCode.new(s_value: " $<i>1 = 1; $<i>$ = 2; "),
              position_in_original_rule_rhs: 1,
              nullable: true,
              precedence_sym: nil,
              lineno: 17,
            ),
            Rule.new(
              id: 3,
              lhs: grammar.find_symbol_by_s_value!("@2"),
              rhs: [],
              token_code: T::UserCode.new(s_value: " $<i>$ = 3; "),
              position_in_original_rule_rhs: 2,
              nullable: true,
              precedence_sym: nil,
              lineno: 18,
            ),
            Rule.new(
              id: 4,
              lhs: grammar.find_symbol_by_s_value!("$@3"),
              rhs: [],
              token_code: T::UserCode.new(s_value: " $<i>$ = 4; "),
              position_in_original_rule_rhs: 3,
              nullable: true,
              precedence_sym: nil,
              lineno: 19,
            ),
            Rule.new(
              id: 5,
              lhs: grammar.find_symbol_by_s_value!("$@4"),
              rhs: [],
              token_code: T::UserCode.new(s_value: " 5; "),
              position_in_original_rule_rhs: 5,
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
              token_code: T::UserCode.new(s_value: " $<i>2; $<i>3; $<i>5; $<i>7; $<i>$ = 1; "),
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
%type <int> emp

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
          grammar = Lrama::Parser.new(y, "parse.y").parse

          expect(grammar.rules).to eq([
            Rule.new(
              id: 0,
              lhs: grammar.find_symbol_by_s_value!("$accept"),
              rhs: [
                grammar.find_symbol_by_s_value!("program"),
                grammar.find_symbol_by_s_value!("EOI"),
              ],
              token_code: nil,
              nullable: false,
              precedence_sym: grammar.find_symbol_by_s_value!("EOI"),
              lineno: 14,
            ),
            Rule.new(
              id: 1,
              lhs: grammar.find_symbol_by_s_value!("program"),
              rhs: [
                grammar.find_symbol_by_s_value!("emp"),
              ],
              token_code: nil,
              nullable: true,
              precedence_sym: nil,
              lineno: 14,
            ),
            Rule.new(
              id: 2,
              lhs: grammar.find_symbol_by_s_value!("emp"),
              rhs: [
              ],
              token_code: T::UserCode.new(s_value: " $$; "),
              nullable: true,
              precedence_sym: nil,
              lineno: 17,
            ),
            Rule.new(
              id: 3,
              lhs: grammar.find_symbol_by_s_value!("emp"),
              rhs: [
              ],
              token_code: T::UserCode.new(s_value: " @$; "),
              nullable: true,
              precedence_sym: nil,
              lineno: 19,
            ),
            Rule.new(
              id: 4,
              lhs: grammar.find_symbol_by_s_value!("emp"),
              rhs: [
              ],
              token_code: T::UserCode.new(s_value: " @0; "),
              nullable: true,
              precedence_sym: nil,
              lineno: 21,
            ),
          ])
        end

        context "includes named references" do
          it "can parse" do
            y = <<~INPUT
%{
// Prologue
%}

%union {
  int i;
}

%token NUM
%type <val> expr

%%

input       : /* empty */
            | input line
;

line        : '\\n'
            | expr '\\n'
                { printf("\\t%.10g\\n", $expr); }
;

expr[result]: NUM
            | expr[left] expr[right] '+'
                { $result = $left + $right; }
            | expr expr '-'
                { $$ = $1 - $2; }
;
            INPUT
            grammar = Lrama::Parser.new(y, "parse.y").parse

            expect(grammar.rules).to eq([
              Rule.new(
                id: 0,
                lhs: grammar.find_symbol_by_s_value!("$accept"),
                rhs: [
                  grammar.find_symbol_by_s_value!("input"),
                  grammar.find_symbol_by_s_value!("YYEOF"),
                ],
                token_code: nil,
                nullable: false,
                precedence_sym: grammar.find_symbol_by_s_value!("YYEOF"),
                lineno: 14,
              ),
              Rule.new(
                id: 1,
                lhs: grammar.find_symbol_by_s_value!("input"),
                rhs: [
                ],
                token_code: nil,
                nullable: true,
                precedence_sym: nil,
                lineno: 14,
              ),
              Rule.new(
                id: 2,
                lhs: grammar.find_symbol_by_s_value!("input"),
                rhs: [
                  grammar.find_symbol_by_s_value!("input"),
                  grammar.find_symbol_by_s_value!("line"),
                ],
                token_code: nil,
                nullable: false,
                precedence_sym: nil,
                lineno: 15,
              ),
              Rule.new(
                id: 3,
                lhs: grammar.find_symbol_by_s_value!("line"),
                rhs: [
                  grammar.find_symbol_by_s_value!("'\\n'"),
                ],
                token_code: nil,
                nullable: false,
                precedence_sym: grammar.find_symbol_by_s_value!("'\\n'"),
                lineno: 18,
              ),
              Rule.new(
                id: 4,
                lhs: grammar.find_symbol_by_s_value!("line"),
                rhs: [
                  grammar.find_symbol_by_s_value!("expr"),
                  grammar.find_symbol_by_s_value!("'\\n'"),
                ],
                token_code: T::UserCode.new(s_value: " printf(\"\\t%.10g\\n\", $expr); "),
                nullable: false,
                precedence_sym: grammar.find_symbol_by_s_value!("'\\n'"),
                lineno: 19,
              ),
              Rule.new(
                id: 5,
                lhs: grammar.find_symbol_by_s_value!("expr"),
                rhs: [
                  grammar.find_symbol_by_s_value!("NUM"),
                ],
                token_code: nil,
                nullable: false,
                precedence_sym: grammar.find_symbol_by_s_value!("NUM"),
                lineno: 23,
              ),
              Rule.new(
                id: 6,
                lhs: grammar.find_symbol_by_s_value!("expr"),
                rhs: [
                  grammar.find_symbol_by_s_value!("expr"),
                  grammar.find_symbol_by_s_value!("expr"),
                  grammar.find_symbol_by_s_value!("'+'"),
                ],
                token_code: T::UserCode.new(s_value: " $result = $left + $right; "),
                nullable: false,
                precedence_sym: grammar.find_symbol_by_s_value!("'+'"),
                lineno: 24,
              ),
              Rule.new(
                id: 7,
                lhs: grammar.find_symbol_by_s_value!("expr"),
                rhs: [
                  grammar.find_symbol_by_s_value!("expr"),
                  grammar.find_symbol_by_s_value!("expr"),
                  grammar.find_symbol_by_s_value!("'-'"),
                ],
                token_code: T::UserCode.new(s_value: " $$ = $1 - $2; "),
                nullable: false,
                precedence_sym: grammar.find_symbol_by_s_value!("'-'"),
                lineno: 26,
              ),
            ])
          end
        end

        context "includes invalid named references" do
          it "raise an error" do
            y = <<~INPUT
%{
// Prologue
%}

%union {
  int i;
}

%token NUM
%type <val> expr

%%

input       : /* empty */
            | input line
;

line        : '\\n'
            | expr '\\n'
                { printf("\\t%.10g\\n", $expr); }
;

expr[result]: NUM
            | expr[left] expr[right] '+'
                { $results = $left + $right; }
            | expr expr '-'
                { $$ = $1 - $2; }
;
            INPUT

            expect { Lrama::Parser.new(y, "parse.y").parse }.to raise_error(/Referring symbol `results` is not found\./)
          end
        end
      end
    end

    describe "error messages" do
      context "error_value has line number and column" do
        it "contains line number and column" do
          y = <<~INPUT
%{
// Prologue
%}

%expect invalid

%%

program: /* empty */
       ;
          INPUT
          expect { Lrama::Parser.new(y, "error_messages/parse.y").parse }.to raise_error(ParseError, <<~ERROR)
            error_messages/parse.y:5:7: parse error on value 'invalid' (IDENTIFIER)
            %expect invalid
                    ^^^^^^^
          ERROR
        end
      end

      context "error_value doesn't have line number and column" do
        it "contains line number and column" do
          y = <<~INPUT
%{
// Prologue
%}

%expect 0 10

%%

program: /* empty */
       ;
          INPUT
          expect { Lrama::Parser.new(y, "error_messages/parse.y").parse }.to raise_error(ParseError, <<~ERROR)
            error_messages/parse.y:5:9: parse error on value 10 (INTEGER)
            %expect 0 10
                      ^^
          ERROR
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
      grammar = Lrama::Parser.new(y, "parse.y").parse
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
        grammar = Lrama::Parser.new(y, "parse.y").parse
        codes = grammar.rules.map(&:token_code)

        expect(codes.count).to eq(3)
        expect(codes[0]).to be nil
        expect(codes[1]).to be nil
        expect(codes[2].references.count).to eq(1)
        expect(codes[2].references[0].ex_tag.s_value).to eq("<l>")
      end
    end
  end
end
