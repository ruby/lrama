# frozen_string_literal: true

RSpec.describe Lrama::Lexer do
  let(:token_class) { Lrama::Lexer::Token }

  describe '#next_token' do
    context 'basic.y' do
      it do
        path = fixture_path("common/basic.y")
        text = File.read(path)
        grammar_file = Lrama::Lexer::GrammarFile.new(path, text)
        lexer = Lrama::Lexer.new(grammar_file)

        expect(lexer.next_token).to eq(['%require', token_class::Token.new(s_value: '%require')])
        expect(lexer.next_token).to eq([:STRING, token_class::Str.new(s_value: '"3.0"')])
        expect(lexer.next_token).to eq(['%{', token_class::Token.new(s_value: '%{')])

        lexer.status = :c_declaration
        lexer.end_symbol = '%}'
        token = lexer.next_token
        expect(token).to eq([:C_DECLARATION, token_class::UserCode.new(s_value: "\n// Prologue\n")])
        expect(token[1].location).to eq Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 7, first_column: 2, last_line: 9, last_column: 0)
        lexer.status = :initial

        expect(lexer.next_token).to eq(['%}', token_class::Token.new(s_value: '%}')])
        expect(lexer.next_token).to eq(['%expect', token_class::Token.new(s_value: '%expect')])
        expect(lexer.next_token).to eq([:INTEGER, token_class::Int.new(s_value: 0)])
        expect(lexer.next_token).to eq(['%define', token_class::Token.new(s_value: '%define')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'api.pure')])
        expect(lexer.next_token).to eq(['%define', token_class::Token.new(s_value: '%define')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'parse.error')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'verbose')])
        expect(lexer.next_token).to eq(['%define', token_class::Token.new(s_value: '%define')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'api.prefix')])
        expect(lexer.next_token).to eq(['{', token_class::Token.new(s_value: '{')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'prefix')])
        expect(lexer.next_token).to eq(['}', token_class::Token.new(s_value: '}')])
        expect(lexer.next_token).to eq(['%printer', token_class::Token.new(s_value: '%printer')])
        expect(lexer.next_token).to eq(['{', token_class::Token.new(s_value: '{')])

        lexer.status = :c_declaration
        lexer.end_symbol = '}'
        token = lexer.next_token
        expect(token).to eq([:C_DECLARATION, token_class::UserCode.new(s_value: "\n    print_int();\n")])
        expect(token[1].location).to eq Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 16, first_column: 10, last_line: 18, last_column: 0)
        lexer.status = :initial

        expect(lexer.next_token).to eq(['}', token_class::Token.new(s_value: '}')])
        expect(lexer.next_token).to eq([:TAG, token_class::Tag.new(s_value: '<int>')])
        expect(lexer.next_token).to eq(['%printer', token_class::Token.new(s_value: '%printer')])
        expect(lexer.next_token).to eq(['{', token_class::Token.new(s_value: '{')])

        lexer.status = :c_declaration
        lexer.end_symbol = '}'
        token = lexer.next_token
        expect(token).to eq([:C_DECLARATION, token_class::UserCode.new(s_value: "\n    print_token();\n")])
        expect(token[1].location).to eq Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 19, first_column: 10, last_line: 21, last_column: 0)
        lexer.status = :initial

        expect(lexer.next_token).to eq(['}', token_class::Token.new(s_value: '}')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'tNUMBER')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'tSTRING')])
        expect(lexer.next_token).to eq(['%lex-param', token_class::Token.new(s_value: '%lex-param')])
        expect(lexer.next_token).to eq(['{', token_class::Token.new(s_value: '{')])

        lexer.status = :c_declaration
        lexer.end_symbol = '}'
        token = lexer.next_token
        expect(token).to eq([:C_DECLARATION, token_class::UserCode.new(s_value: 'struct lex_params *p')])
        expect(token[1].location).to eq Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 23, first_column: 12, last_line: 23, last_column: 32)
        lexer.status = :initial

        expect(lexer.next_token).to eq(['}', token_class::Token.new(s_value: '}')])
        expect(lexer.next_token).to eq(['%parse-param', token_class::Token.new(s_value: '%parse-param')])
        expect(lexer.next_token).to eq(['{', token_class::Token.new(s_value: '{')])

        lexer.status = :c_declaration
        lexer.end_symbol = '}'
        token = lexer.next_token
        expect(token).to eq([:C_DECLARATION, token_class::UserCode.new(s_value: 'struct parse_params *p')])
        expect(token[1].location).to eq Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 24, first_column: 14, last_line: 24, last_column: 36)
        lexer.status = :initial

        expect(lexer.next_token).to eq(['}', token_class::Token.new(s_value: '}')])
        expect(lexer.next_token).to eq(['%initial-action', token_class::Token.new(s_value: '%initial-action')])
        expect(lexer.next_token).to eq(['{', token_class::Token.new(s_value: '{')])

        lexer.status = :c_declaration
        lexer.end_symbol = '}'
        token = lexer.next_token
        expect(token).to eq([:C_DECLARATION, token_class::UserCode.new(s_value: "\n    initial_action_func(@$);\n")])
        expect(token[1].location).to eq Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 27, first_column: 1, last_line: 29, last_column: 0)
        lexer.status = :initial

        expect(lexer.next_token).to eq(['}', token_class::Token.new(s_value: '}')])
        expect(lexer.next_token).to eq([';', token_class::Token.new(s_value: ';')])
        expect(lexer.next_token).to eq([';', token_class::Token.new(s_value: ';')])
        expect(lexer.next_token).to eq(['%union', token_class::Token.new(s_value: '%union')])
        expect(lexer.next_token).to eq(['{', token_class::Token.new(s_value: '{')])

        lexer.status = :c_declaration
        lexer.end_symbol = '}'
        token = lexer.next_token
        expect(token).to eq([:C_DECLARATION, token_class::UserCode.new(s_value: "\n    int i;\n    long l;\n    char *str;\n")])
        expect(token[1].location).to eq Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 31, first_column: 8, last_line: 35, last_column: 0)
        lexer.status = :initial

        expect(lexer.next_token).to eq(['}', token_class::Token.new(s_value: '}')])
        expect(lexer.next_token).to eq(['%token', token_class::Token.new(s_value: '%token')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'EOI')])
        expect(lexer.next_token).to eq([:INTEGER, token_class::Int.new(s_value: 0)])
        expect(lexer.next_token).to eq([:STRING, token_class::Str.new(s_value: '"EOI"')])
        expect(lexer.next_token).to eq(['%token', token_class::Token.new(s_value: '%token')])
        expect(lexer.next_token).to eq([:TAG, token_class::Tag.new(s_value: '<i>')])
        expect(lexer.next_token).to eq([:CHARACTER, token_class::Char.new(s_value: "'\\\\'")])
        expect(lexer.next_token).to eq([:STRING, token_class::Str.new(s_value: '"backslash"')])
        expect(lexer.next_token).to eq(['%token', token_class::Token.new(s_value: '%token')])
        expect(lexer.next_token).to eq([:TAG, token_class::Tag.new(s_value: '<i>')])
        expect(lexer.next_token).to eq([:CHARACTER, token_class::Char.new(s_value: "'\\13'")])
        expect(lexer.next_token).to eq([:STRING, token_class::Str.new(s_value: '"escaped vertical tab"')])
        expect(lexer.next_token).to eq(['%token', token_class::Token.new(s_value: '%token')])
        expect(lexer.next_token).to eq([:TAG, token_class::Tag.new(s_value: '<i>')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'keyword_class')])
        expect(lexer.next_token).to eq(['%token', token_class::Token.new(s_value: '%token')])
        expect(lexer.next_token).to eq([:TAG, token_class::Tag.new(s_value: '<i>')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'keyword_class2')])
        expect(lexer.next_token).to eq(['%token', token_class::Token.new(s_value: '%token')])
        expect(lexer.next_token).to eq([:TAG, token_class::Tag.new(s_value: '<l>')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'tNUMBER')])
        expect(lexer.next_token).to eq(['%token', token_class::Token.new(s_value: '%token')])
        expect(lexer.next_token).to eq([:TAG, token_class::Tag.new(s_value: '<str>')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'tSTRING')])
        expect(lexer.next_token).to eq(['%token', token_class::Token.new(s_value: '%token')])
        expect(lexer.next_token).to eq([:TAG, token_class::Tag.new(s_value: '<i>')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'keyword_end')])
        expect(lexer.next_token).to eq([:STRING, token_class::Str.new(s_value: '"end"')])
        expect(lexer.next_token).to eq(['%token', token_class::Token.new(s_value: '%token')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'tPLUS')])
        expect(lexer.next_token).to eq([:STRING, token_class::Str.new(s_value: '"+"')])
        expect(lexer.next_token).to eq(['%token', token_class::Token.new(s_value: '%token')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'tMINUS')])
        expect(lexer.next_token).to eq([:STRING, token_class::Str.new(s_value: '"-"')])
        expect(lexer.next_token).to eq(['%token', token_class::Token.new(s_value: '%token')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'tEQ')])
        expect(lexer.next_token).to eq([:STRING, token_class::Str.new(s_value: '"="')])
        expect(lexer.next_token).to eq(['%token', token_class::Token.new(s_value: '%token')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'tEQEQ')])
        expect(lexer.next_token).to eq([:STRING, token_class::Str.new(s_value: '"=="')])
        expect(lexer.next_token).to eq(['%type', token_class::Token.new(s_value: '%type')])
        expect(lexer.next_token).to eq([:TAG, token_class::Tag.new(s_value: '<i>')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'class')])
        expect(lexer.next_token).to eq(['%nonassoc', token_class::Token.new(s_value: '%nonassoc')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'tEQEQ')])
        expect(lexer.next_token).to eq(['%left', token_class::Token.new(s_value: '%left')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'tPLUS')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'tMINUS')])
        expect(lexer.next_token).to eq([:CHARACTER, token_class::Char.new(s_value: "'>'")])
        expect(lexer.next_token).to eq(['%right', token_class::Token.new(s_value: '%right')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'tEQ')])
        expect(lexer.next_token).to eq(['%%', token_class::Token.new(s_value: '%%')])
        expect(lexer.next_token).to eq([:IDENT_COLON, token_class::Ident.new(s_value: 'program')])
        expect(lexer.next_token).to eq([':', token_class::Token.new(s_value: ':')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'class')])
        expect(lexer.next_token).to eq(['|', token_class::Token.new(s_value: '|')])
        expect(lexer.next_token).to eq([:CHARACTER, token_class::Char.new(s_value: "'+'")])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'strings_1')])
        expect(lexer.next_token).to eq(['|', token_class::Token.new(s_value: '|')])
        expect(lexer.next_token).to eq([:CHARACTER, token_class::Char.new(s_value: "'-'")])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'strings_2')])
        expect(lexer.next_token).to eq([';', token_class::Token.new(s_value: ';')])
        expect(lexer.next_token).to eq([:IDENT_COLON, token_class::Ident.new(s_value: 'class')])
        expect(lexer.next_token).to eq([':', token_class::Token.new(s_value: ':')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'keyword_class')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'tSTRING')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'keyword_end')])
        expect(lexer.next_token).to eq(['%prec', token_class::Token.new(s_value: '%prec')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'tPLUS')])
        expect(lexer.next_token).to eq(['{', token_class::Token.new(s_value: '{')])

        lexer.status = :c_declaration
        lexer.end_symbol = '}'
        token = lexer.next_token
        expect(token).to eq([:C_DECLARATION, token_class::UserCode.new(s_value: " code 1 ")])
        expect(token[1].location).to eq Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 64, first_column: 11, last_line: 64, last_column: 19)
        lexer.status = :initial

        expect(lexer.next_token).to eq(['}', token_class::Token.new(s_value: '}')])
        expect(lexer.next_token).to eq(['|', token_class::Token.new(s_value: '|')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'keyword_class')])
        expect(lexer.next_token).to eq(['{', token_class::Token.new(s_value: '{')])

        lexer.status = :c_declaration
        lexer.end_symbol = '}'
        token = lexer.next_token
        expect(token).to eq([:C_DECLARATION, token_class::UserCode.new(s_value: " code 2 ")])
        expect(token[1].location).to eq Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 65, first_column: 23, last_line: 65, last_column: 31)
        lexer.status = :initial

        expect(lexer.next_token).to eq(['}', token_class::Token.new(s_value: '}')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'tSTRING')])
        expect(lexer.next_token).to eq([:CHARACTER, token_class::Char.new(s_value: "'!'")])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'keyword_end')])
        expect(lexer.next_token).to eq(['{', token_class::Token.new(s_value: '{')])

        lexer.status = :c_declaration
        lexer.end_symbol = '}'
        token = lexer.next_token
        expect(token).to eq([:C_DECLARATION, token_class::UserCode.new(s_value: " code 3 ")])
        expect(token[1].location).to eq Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 65, first_column: 58, last_line: 65, last_column: 66)
        lexer.status = :initial

        expect(lexer.next_token).to eq(['}', token_class::Token.new(s_value: '}')])
        expect(lexer.next_token).to eq(['%prec', token_class::Token.new(s_value: '%prec')])
        expect(lexer.next_token).to eq([:STRING, token_class::Str.new(s_value: '"="')])
        expect(lexer.next_token).to eq(['|', token_class::Token.new(s_value: '|')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'keyword_class')])
        expect(lexer.next_token).to eq(['{', token_class::Token.new(s_value: '{')])

        lexer.status = :c_declaration
        lexer.end_symbol = '}'
        token = lexer.next_token
        expect(token).to eq([:C_DECLARATION, token_class::UserCode.new(s_value: " code 4 ")])
        expect(token[1].location).to eq Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 66, first_column: 23, last_line: 66, last_column: 31)
        lexer.status = :initial

        expect(lexer.next_token).to eq(['}', token_class::Token.new(s_value: '}')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'tSTRING')])
        expect(lexer.next_token).to eq([:CHARACTER, token_class::Char.new(s_value: "'?'")])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'keyword_end')])
        expect(lexer.next_token).to eq(['{', token_class::Token.new(s_value: '{')])

        lexer.status = :c_declaration
        lexer.end_symbol = '}'
        token = lexer.next_token
        expect(token).to eq([:C_DECLARATION, token_class::UserCode.new(s_value: " code 5 ")])
        expect(token[1].location).to eq Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 66, first_column: 58, last_line: 66, last_column: 66)
        lexer.status = :initial

        expect(lexer.next_token).to eq(['}', token_class::Token.new(s_value: '}')])
        expect(lexer.next_token).to eq(['%prec', token_class::Token.new(s_value: '%prec')])
        expect(lexer.next_token).to eq([:CHARACTER, token_class::Char.new(s_value: "'>'")])
        expect(lexer.next_token).to eq([';', token_class::Token.new(s_value: ';')])
        expect(lexer.next_token).to eq([';', token_class::Token.new(s_value: ';')])
        expect(lexer.next_token).to eq([:IDENT_COLON, token_class::Ident.new(s_value: 'strings_1')])
        expect(lexer.next_token).to eq([':', token_class::Token.new(s_value: ':')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'string_1')])
        expect(lexer.next_token).to eq([';', token_class::Token.new(s_value: ';')])
        expect(lexer.next_token).to eq([:IDENT_COLON, token_class::Ident.new(s_value: 'strings_2')])
        expect(lexer.next_token).to eq([':', token_class::Token.new(s_value: ':')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'string_1')])
        expect(lexer.next_token).to eq(['|', token_class::Token.new(s_value: '|')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'string_2')])
        expect(lexer.next_token).to eq([';', token_class::Token.new(s_value: ';')])
        expect(lexer.next_token).to eq([:IDENT_COLON, token_class::Ident.new(s_value: 'string_1')])
        expect(lexer.next_token).to eq([':', token_class::Token.new(s_value: ':')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'string')])
        expect(lexer.next_token).to eq([';', token_class::Token.new(s_value: ';')])
        expect(lexer.next_token).to eq([:IDENT_COLON, token_class::Ident.new(s_value: 'string_2')])
        expect(lexer.next_token).to eq([':', token_class::Token.new(s_value: ':')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'string')])
        expect(lexer.next_token).to eq([:CHARACTER, token_class::Char.new(s_value: "'+'")])
        expect(lexer.next_token).to eq([';', token_class::Token.new(s_value: ';')])
        expect(lexer.next_token).to eq([:IDENT_COLON, token_class::Ident.new(s_value: 'string')])
        expect(lexer.next_token).to eq([':', token_class::Token.new(s_value: ':')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'tSTRING')])
        expect(lexer.next_token).to eq([';', token_class::Token.new(s_value: ';')])
        expect(lexer.next_token).to eq([:IDENT_COLON, token_class::Ident.new(s_value: 'unused')])
        expect(lexer.next_token).to eq([':', token_class::Token.new(s_value: ':')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'tNUMBER')])
        expect(lexer.next_token).to eq([';', token_class::Token.new(s_value: ';')])
        expect(lexer.next_token).to eq(['%%', token_class::Token.new(s_value: '%%')])
        expect(lexer.next_token).to eq(nil)
      end
    end

    context 'nullable.y' do
      it do
        path = fixture_path("common/nullable.y")
        text = File.read(path)
        grammar_file = Lrama::Lexer::GrammarFile.new(path, text)
        lexer = Lrama::Lexer.new(grammar_file)

        expect(lexer.next_token).to eq(['%require', token_class::Token.new(s_value: '%require')])
        expect(lexer.next_token).to eq([:STRING, token_class::Str.new(s_value: '"3.0"')])
        expect(lexer.next_token).to eq(['%{', token_class::Token.new(s_value: '%{')])

        lexer.status = :c_declaration
        lexer.end_symbol = '%}'
        token = lexer.next_token
        expect(token).to eq([:C_DECLARATION, token_class::UserCode.new(s_value: "\n// Prologue\n")])
        expect(token[1].location).to eq Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 7, first_column: 2, last_line: 9, last_column: 0)
        lexer.status = :initial

        expect(lexer.next_token).to eq(['%}', token_class::Token.new(s_value: '%}')])
        expect(lexer.next_token).to eq(['%token', token_class::Token.new(s_value: '%token')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'tNUMBER')])
        expect(lexer.next_token).to eq(['%%', token_class::Token.new(s_value: '%%')])
        expect(lexer.next_token).to eq([:IDENT_COLON, token_class::Ident.new(s_value: 'program')])
        expect(lexer.next_token).to eq([':', token_class::Token.new(s_value: ':')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'stmt')])
        expect(lexer.next_token).to eq([';', token_class::Token.new(s_value: ';')])
        expect(lexer.next_token).to eq([:IDENT_COLON, token_class::Ident.new(s_value: 'stmt')])
        expect(lexer.next_token).to eq([':', token_class::Token.new(s_value: ':')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'expr')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'opt_semicolon')])
        expect(lexer.next_token).to eq(['|', token_class::Token.new(s_value: '|')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'opt_expr')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'opt_colon')])
        expect(lexer.next_token).to eq(['|', token_class::Token.new(s_value: '|')])
        expect(lexer.next_token).to eq(['%empty', token_class::Token.new(s_value: '%empty')])
        expect(lexer.next_token).to eq([';', token_class::Token.new(s_value: ';')])
        expect(lexer.next_token).to eq([:IDENT_COLON, token_class::Ident.new(s_value: 'expr')])
        expect(lexer.next_token).to eq([':', token_class::Token.new(s_value: ':')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'tNUMBER')])
        expect(lexer.next_token).to eq([';', token_class::Token.new(s_value: ';')])
        expect(lexer.next_token).to eq([:IDENT_COLON, token_class::Ident.new(s_value: 'opt_expr')])
        expect(lexer.next_token).to eq([':', token_class::Token.new(s_value: ':')])
        expect(lexer.next_token).to eq(['|', token_class::Token.new(s_value: '|')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'expr')])
        expect(lexer.next_token).to eq([';', token_class::Token.new(s_value: ';')])
        expect(lexer.next_token).to eq([:IDENT_COLON, token_class::Ident.new(s_value: 'opt_semicolon')])
        expect(lexer.next_token).to eq([':', token_class::Token.new(s_value: ':')])
        expect(lexer.next_token).to eq(['|', token_class::Token.new(s_value: '|')])
        expect(lexer.next_token).to eq([:CHARACTER, token_class::Char.new(s_value: "';'")])
        expect(lexer.next_token).to eq([';', token_class::Token.new(s_value: ';')])
        expect(lexer.next_token).to eq([:IDENT_COLON, token_class::Ident.new(s_value: 'opt_colon')])
        expect(lexer.next_token).to eq([':', token_class::Token.new(s_value: ':')])
        expect(lexer.next_token).to eq(['%empty', token_class::Token.new(s_value: '%empty')])
        expect(lexer.next_token).to eq(['|', token_class::Token.new(s_value: '|')])
        expect(lexer.next_token).to eq([:CHARACTER, token_class::Char.new(s_value: "'.'")])
        expect(lexer.next_token).to eq([';', token_class::Token.new(s_value: ';')])
        expect(lexer.next_token).to eq(['%%', token_class::Token.new(s_value: '%%')])
        expect(lexer.next_token).to eq(nil)
      end
    end

    context 'precedence.y' do
      it do
        path = fixture_path("common/precedence.y")
        text = File.read(path)
        grammar_file = Lrama::Lexer::GrammarFile.new(path, text)
        lexer = Lrama::Lexer.new(grammar_file)
        expect(lexer.next_token).to eq(['%{', token_class::Token.new(s_value: '%{')])
        lexer.status = :c_declaration
        lexer.end_symbol = '%}'
        token = lexer.next_token
        expect(token).to eq([:C_DECLARATION, token_class::UserCode.new(s_value: "\n#include <stdio.h>\n#include <stdlib.h>\n\nint yylex(void);\nvoid yyerror(const char *s);\n")])
        lexer.status = :initial
        expect(lexer.next_token).to eq(['%}', token_class::Token.new(s_value: '%}')])
        expect(lexer.next_token).to eq(['%union', token_class::Token.new(s_value: '%union')])
        expect(lexer.next_token).to eq(['{', token_class::Token.new(s_value: '{')])
        lexer.status = :c_declaration
        lexer.end_symbol = '}'
        token = lexer.next_token
        expect(token).to eq([:C_DECLARATION, token_class::UserCode.new(s_value: "\n    int i;\n    void* p;\n")])
        lexer.status = :initial
        expect(lexer.next_token).to eq(['}', token_class::Token.new(s_value: '}')])
        expect(lexer.next_token).to eq(['%left', token_class::Token.new(s_value: '%left')])
        expect(lexer.next_token).to eq([:TAG, token_class::Tag.new(s_value: '<i>')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'PLUS')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'MINUS')])
        expect(lexer.next_token).to eq([:TAG, token_class::Tag.new(s_value: '<p>')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'ADD_OP')])
        expect(lexer.next_token).to eq(['%left', token_class::Token.new(s_value: '%left')])
        expect(lexer.next_token).to eq([:TAG, token_class::Tag.new(s_value: '<i>')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'MULT')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'DIV')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'MOD')])
        expect(lexer.next_token).to eq([:TAG, token_class::Tag.new(s_value: '<p>')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'MULT_OP')])
        expect(lexer.next_token).to eq(['%token', token_class::Token.new(s_value: '%token')])
        expect(lexer.next_token).to eq([:TAG, token_class::Tag.new(s_value: '<i>')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'NUMBER')])
        expect(lexer.next_token).to eq(['%token', token_class::Token.new(s_value: '%token')])
        expect(lexer.next_token).to eq([:TAG, token_class::Tag.new(s_value: '<i>')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'LPAREN')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'RPAREN')])
        expect(lexer.next_token).to eq(['%type', token_class::Token.new(s_value: '%type')])
        expect(lexer.next_token).to eq([:TAG, token_class::Tag.new(s_value: '<i>')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'expr')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'term')])
        expect(lexer.next_token).to eq([:IDENTIFIER, token_class::Ident.new(s_value: 'factor')])
        expect(lexer.next_token).to eq(['%%', token_class::Token.new(s_value: '%%')])
        expect(lexer.next_token).to eq([:IDENT_COLON, token_class::Ident.new(s_value: 'program')])
        expect(lexer.next_token).to eq([':', token_class::Token.new(s_value: ':')])
      end
    end
  end

  context 'unexpected_token.y' do
    it do
      path = fixture_path("common/unexpected_token.y")
      text = File.read(path)
      grammar_file = Lrama::Lexer::GrammarFile.new(path, text)
      lexer = Lrama::Lexer.new(grammar_file)

      expect { lexer.next_token }.to raise_error(ParseError, "Unexpected token: @invalid.")
    end
  end

  context 'unexpected_c_code.y' do
    it do
      grammar_file = Lrama::Lexer::GrammarFile.new("invalid.y", "@invalid")
      lexer = Lrama::Lexer.new(grammar_file)
      lexer.status = :c_declaration
      lexer.end_symbol = "%}"

      expect { lexer.next_token }.to raise_error(ParseError, "Unexpected code: @invalid.")
    end
  end

  it 'lex a line comment without newline' do
    grammar_file = Lrama::Lexer::GrammarFile.new("comment.y", "// foo")
    lexer = Lrama::Lexer.new(grammar_file)

    expect(lexer.next_token).to be_nil
  end
end
