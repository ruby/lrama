RSpec.describe Lrama::Context do
  let(:warning) { Lrama::Warning.new }

  describe "basic" do
    it do
      y = File.read(fixture_path("context/basic.y"))
      grammar = Lrama::Parser.new(y).parse
      states = Lrama::States.new(grammar, warning)
      states.compute
      context = Lrama::Context.new(states)

      # These expectations are based on Bison 3.8.2.
      # generating file.
      expect(context.yytokentype).to eq([
        ["YYEMPTY",         -2, nil],
        ["EOI",              0, "\"EOI\""],
        ["YYerror",        256, "error"],
        ["YYUNDEF",        257, "\"invalid token\""],
        ["keyword_class",  258, "keyword_class"],
        ["keyword_class2", 259, "keyword_class2"],
        ["tNUMBER",        260, "tNUMBER"],
        ["tSTRING",        261, "tSTRING"],
        ["keyword_end",    262, "\"end\""],
        ["tPLUS",          263, "\"+\""],
        ["tMINUS",         264, "\"-\""],
        ["tEQ",            265, "\"=\""],
        ["tEQEQ",          266, "\"==\""],
      ])
      expect(context.yysymbol_kind_t).to eq([
        ["YYSYMBOL_YYEMPTY",                -2, nil],
        ["YYSYMBOL_YYEOF",                   0, "\"EOI\""],
        ["YYSYMBOL_YYerror",                 1, "error"],
        ["YYSYMBOL_YYUNDEF",                 2, "\"invalid token\""],
        ["YYSYMBOL_3_backslash_",            3, "\"backslash\""],
        ["YYSYMBOL_4_escaped_vertical_tab_", 4, "\"escaped vertical tab\""],
        ["YYSYMBOL_keyword_class",           5, "keyword_class"],
        ["YYSYMBOL_keyword_class2",          6, "keyword_class2"],
        ["YYSYMBOL_tNUMBER",                 7, "tNUMBER"],
        ["YYSYMBOL_tSTRING",                 8, "tSTRING"],
        ["YYSYMBOL_keyword_end",             9, "\"end\""],
        ["YYSYMBOL_tPLUS",                  10, "\"+\""],
        ["YYSYMBOL_tMINUS",                 11, "\"-\""],
        ["YYSYMBOL_tEQ",                    12, "\"=\""],
        ["YYSYMBOL_tEQEQ",                  13, "\"==\""],
        ["YYSYMBOL_14_",                    14, "'>'"],
        ["YYSYMBOL_15_",                    15, "'+'"],
        ["YYSYMBOL_16_",                    16, "'-'"],
        ["YYSYMBOL_17_",                    17, "'!'"],
        ["YYSYMBOL_YYACCEPT",               18, "$accept"],
        ["YYSYMBOL_program",                19, "program"],
        ["YYSYMBOL_class",                  20, "class"],
        ["YYSYMBOL_21_1",                   21, "$@1"],
        ["YYSYMBOL_strings_1",              22, "strings_1"],
        ["YYSYMBOL_strings_2",              23, "strings_2"],
        ["YYSYMBOL_string_1",               24, "string_1"],
        ["YYSYMBOL_string_2",               25, "string_2"],
        ["YYSYMBOL_string",                 26, "string"],
      ])
      expect(context.yyfinal).to eq(15)
      expect(context.yylast).to eq(11)
      expect(context.yyntokens).to eq(18)
      expect(context.yynnts).to eq(9)
      expect(context.yynrules).to eq(13)
      expect(context.yynstates).to eq(21)
      expect(context.yymaxutok).to eq(266)
      expect(context.yytranslate).to eq([
         0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
         2,     4,     2,     2,     2,     2,     2,     2,     2,     2,
         2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
         2,     2,     2,    17,     2,     2,     2,     2,     2,     2,
         2,     2,     2,    15,     2,    16,     2,     2,     2,     2,
         2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
         2,     2,    14,     2,     2,     2,     2,     2,     2,     2,
         2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
         2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
         2,     2,     3,     2,     2,     2,     2,     2,     2,     2,
         2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
         2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
         2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
         2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
         2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
         2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
         2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
         2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
         2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
         2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
         2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
         2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
         2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
         2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
         2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
         2,     2,     2,     2,     2,     2,     1,     2,     5,     6,
         7,     8,     9,    10,    11,    12,    13
      ])
      expect(context.yytname[context.yytranslate[11]]).to eq("\"escaped vertical tab\"")
      expect(context.yytname[context.yytranslate[258]]).to eq("keyword_class")
      expect(context.yyrline).to eq([
         0,    57,    57,    58,    59,    62,    64,    64,    67,    70,
        71,    74,    77,    80
      ])
      expect(context.yytname).to eq([
        "\"EOI\"", "error", "\"invalid token\"", "\"backslash\"",
        "\"escaped vertical tab\"", "keyword_class", "keyword_class2", "tNUMBER",
        "tSTRING", "\"end\"", "\"+\"", "\"-\"", "\"=\"", "\"==\"", "'>'", "'+'",
        "'-'", "'!'", "$accept", "program", "class", "$@1", "strings_1",
        "strings_2", "string_1", "string_2", "string"
      ])
      expect(context.yypact_ninf).to eq(-11)
      expect(context.yytable_ninf).to eq(-1)
      expect(context.yypact).to eq([
        -5,    -6,    -4,    -4,     3,   -11,    -8,   -11,   -11,   -11,
       -11,   -11,   -11,   -11,   -10,   -11,   -11,   -11,   -11,    -3,
       -11
      ])
      expect(context.yydefact).to eq([
         0,     0,     0,     0,     0,     2,     0,    13,     3,     8,
        11,     4,     9,    10,    11,     1,     5,     6,    12,     0,
         7
      ])
      expect(context.yypgoto).to eq([
       -11,   -11,   -11,   -11,   -11,   -11,     4,   -11,     5
      ])
      expect(context.yydefgoto).to eq([
         0,     4,     5,    19,     8,    11,     9,    13,    10
      ])
      expect(context.yytable).to eq([
         1,    16,     6,    15,     7,    18,    20,    12,    14,    17,
         2,     3
      ])
      expect(context.yycheck).to eq([
         5,     9,     8,     0,     8,    15,     9,     3,     3,    17,
        15,    16
      ])
      expect(context.yystos).to eq([
         0,     5,    15,    16,    19,    20,     8,     8,    22,    24,
        26,    23,    24,    25,    26,     0,     9,    17,    15,    21,
         9
      ])
      expect(context.yyr1).to eq([
         0,    18,    19,    19,    19,    20,    21,    20,    22,    23,
        23,    24,    25,    26
      ])
      expect(context.yyr2).to eq([
         0,     2,     1,     2,     2,     3,     0,     5,     1,     1,
         1,     1,     2,     1
      ])
    end
  end

  describe "compute_yydefact" do
    describe "S/R conflicts are resolved to reduce" do
      it "does not include shift into actions" do
        y = <<~INPUT
%{
// Prologue
%}

%union {
  int i;
}

%token unary "+@"
%token tNUMBER

%left  '+' '-'
%right unary

%%

program: expr ;

expr: unary expr
    | expr '+' expr
    | expr '-' expr
    | arg
    ;

arg: tNUMBER ;

%%
        INPUT

        grammar = Lrama::Parser.new(y).parse
        states = Lrama::States.new(grammar, warning)
        states.compute
        context = Lrama::Context.new(states)

        expect(context.yypact).to eq([
          -2,    -2,    -3,     3,     0,    -3,    -3,    -3,    -2,    -2,
          -3,    -3
        ])
        expect(context.yypgoto).to eq([
          -3,    -3,    -1,    -3
        ])
        expect(context.yycheck).to eq([
          1,     3,     4,     0,    -1,     5,     6,     8,     9
        ])
        expect(context.yytable).to eq([
          6,     1,     2,     7,     0,     8,     9,    10,    11
        ])
      end
    end

    describe "R/R conflicts are resolved by look ahead tokens" do
      it "includes reduce into actions" do
        y = <<~INPUT
%{
// Prologue
%}

%union {
  int i;
}

%token tNUMBER

%%

program: stmt ;

stmt: expr1 ';'
    | expr2 '.'
    ;

expr1: tNUMBER ;

expr2: tNUMBER ;

%%
        INPUT

        grammar = Lrama::Parser.new(y).parse
        states = Lrama::States.new(grammar, warning)
        states.compute
        context = Lrama::Context.new(states)

        expect(context.yydefact).to eq([
          0,     5,     0,     2,     0,     0,     1,     3,     4
        ])
        expect(context.yydefgoto).to eq([
          0,     2,     3,     4,     5
        ])

        expect(context.yypact).to eq([
          -3,    -4,     2,    -5,    -1,     0,    -5,    -5,    -5
        ])
        expect(context.yypgoto).to eq([
          -5,    -5,    -5,    -5,    -5
        ])
        expect(context.yycheck).to eq([
          3,     5,     0,     4,    -1,     5
        ])
        expect(context.yytable).to eq([
          1,    -6,     6,     7,     0,     8
        ])
      end
    end
  end
end
