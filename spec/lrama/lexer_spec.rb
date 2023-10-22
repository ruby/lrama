RSpec.describe Lrama::Lexer do
  Token = Lrama::Lexer::Token

  describe '#next_token' do
    context 'basic.y' do
      it do
        text = File.read(fixture_path("common/basic.y"))
        lexer = Lrama::Lexer.new(text)

        expect(lexer.next_token).to eq(['%require', '%require'])
        expect(lexer.next_token).to eq([:STRING, '"3.0"'])
        expect(lexer.next_token).to eq(['%{', '%{'])

        lexer.status = :c_declaration; lexer.end_symbol = '%}'
        expect(lexer.next_token).to eq([:C_DECLARATION, Token.new(type: Token::User_code, s_value: "\n// Prologue\n")])
        lexer.status = :initial

        expect(lexer.next_token).to eq(['%}', '%}'])
        expect(lexer.next_token).to eq(['%expect', '%expect'])
        expect(lexer.next_token).to eq([:INTEGER, 0])
        expect(lexer.next_token).to eq(['%define', '%define'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'api.pure')])
        expect(lexer.next_token).to eq(['%define', '%define'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'parse.error')])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'verbose')])
        expect(lexer.next_token).to eq(['%printer', '%printer'])
        expect(lexer.next_token).to eq(['{', '{'])

        lexer.status = :c_declaration; lexer.end_symbol = '}'
        expect(lexer.next_token).to eq([:C_DECLARATION, Token.new(type: Token::User_code, s_value: "\n    print_int();\n")])
        lexer.status = :initial

        expect(lexer.next_token).to eq(['}', '}'])
        expect(lexer.next_token).to eq([:TAG, Token.new(type: Token::Tag, s_value: '<int>')])
        expect(lexer.next_token).to eq(['%printer', '%printer'])
        expect(lexer.next_token).to eq(['{', '{'])

        lexer.status = :c_declaration; lexer.end_symbol = '}'
        expect(lexer.next_token).to eq([:C_DECLARATION, Token.new(type: Token::User_code, s_value: "\n    print_token();\n")])
        lexer.status = :initial

        expect(lexer.next_token).to eq(['}', '}'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'tNUMBER')])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'tSTRING')])
        expect(lexer.next_token).to eq(['%lex-param', '%lex-param'])
        expect(lexer.next_token).to eq(['{', '{'])

        lexer.status = :c_declaration; lexer.end_symbol = '}'
        expect(lexer.next_token).to eq([:C_DECLARATION, Token.new(type: Token::User_code, s_value: 'struct lex_params *p')])
        lexer.status = :initial

        expect(lexer.next_token).to eq(['}', '}'])
        expect(lexer.next_token).to eq(['%parse-param', '%parse-param'])
        expect(lexer.next_token).to eq(['{', '{'])

        lexer.status = :c_declaration; lexer.end_symbol = '}'
        expect(lexer.next_token).to eq([:C_DECLARATION, Token.new(type: Token::User_code, s_value: 'struct parse_params *p')])
        lexer.status = :initial

        expect(lexer.next_token).to eq(['}', '}'])
        expect(lexer.next_token).to eq(['%initial-action', '%initial-action'])
        expect(lexer.next_token).to eq(['{', '{'])

        lexer.status = :c_declaration; lexer.end_symbol = '}'
        expect(lexer.next_token).to eq([:C_DECLARATION, Token.new(type: Token::User_code, s_value: "\n    initial_action_func(@$);\n")])
        lexer.status = :initial

        expect(lexer.next_token).to eq(['}', '}'])
        expect(lexer.next_token).to eq([';', ';'])
        expect(lexer.next_token).to eq(['%union', '%union'])
        expect(lexer.next_token).to eq(['{', '{'])

        lexer.status = :c_declaration; lexer.end_symbol = '}'
        expect(lexer.next_token).to eq([:C_DECLARATION, Token.new(type: Token::User_code, s_value: "\n    int i;\n    long l;\n    char *str;\n")])
        lexer.status = :initial

        expect(lexer.next_token).to eq(['}', '}'])
        expect(lexer.next_token).to eq(['%token', '%token'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'EOI')])
        expect(lexer.next_token).to eq([:INTEGER, 0])
        expect(lexer.next_token).to eq([:STRING, '"EOI"'])
        expect(lexer.next_token).to eq(['%token', '%token'])
        expect(lexer.next_token).to eq([:TAG, Token.new(type: Token::Tag, s_value: '<i>')])
        expect(lexer.next_token).to eq([:CHARACTER, Token.new(type: Token::Char, s_value: "'\\\\'")])
        expect(lexer.next_token).to eq([:STRING, '"backslash"'])
        expect(lexer.next_token).to eq(['%token', '%token'])
        expect(lexer.next_token).to eq([:TAG, Token.new(type: Token::Tag, s_value: '<i>')])
        expect(lexer.next_token).to eq([:CHARACTER, Token.new(type: Token::Char, s_value: "'\\13'")])
        expect(lexer.next_token).to eq([:STRING, '"escaped vertical tab"'])
        expect(lexer.next_token).to eq(['%token', '%token'])
        expect(lexer.next_token).to eq([:TAG, Token.new(type: Token::Tag, s_value: '<i>')])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'keyword_class')])
        expect(lexer.next_token).to eq(['%token', '%token'])
        expect(lexer.next_token).to eq([:TAG, Token.new(type: Token::Tag, s_value: '<i>')])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'keyword_class2')])
        expect(lexer.next_token).to eq(['%token', '%token'])
        expect(lexer.next_token).to eq([:TAG, Token.new(type: Token::Tag, s_value: '<l>')])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'tNUMBER')])
        expect(lexer.next_token).to eq(['%token', '%token'])
        expect(lexer.next_token).to eq([:TAG, Token.new(type: Token::Tag, s_value: '<str>')])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'tSTRING')])
        expect(lexer.next_token).to eq(['%token', '%token'])
        expect(lexer.next_token).to eq([:TAG, Token.new(type: Token::Tag, s_value: '<i>')])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'keyword_end')])
        expect(lexer.next_token).to eq([:STRING, '"end"'])
        expect(lexer.next_token).to eq(['%token', '%token'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'tPLUS')])
        expect(lexer.next_token).to eq([:STRING, '"+"'])
        expect(lexer.next_token).to eq(['%token', '%token'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'tMINUS')])
        expect(lexer.next_token).to eq([:STRING, '"-"'])
        expect(lexer.next_token).to eq(['%token', '%token'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'tEQ')])
        expect(lexer.next_token).to eq([:STRING, '"="'])
        expect(lexer.next_token).to eq(['%token', '%token'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'tEQEQ')])
        expect(lexer.next_token).to eq([:STRING, '"=="'])
        expect(lexer.next_token).to eq(['%type', '%type'])
        expect(lexer.next_token).to eq([:TAG, Token.new(type: Token::Tag, s_value: '<i>')])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'class')])
        expect(lexer.next_token).to eq(['%nonassoc', '%nonassoc'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'tEQEQ')])
        expect(lexer.next_token).to eq(['%left', '%left'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'tPLUS')])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'tMINUS')])
        expect(lexer.next_token).to eq([:CHARACTER, Token.new(type: Token::Char, s_value: "'>'")])
        expect(lexer.next_token).to eq(['%right', '%right'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'tEQ')])
        expect(lexer.next_token).to eq(['%%', '%%'])
        expect(lexer.next_token).to eq([:IDENT_COLON, Token.new(type: Token::Ident, s_value: 'program')])
        expect(lexer.next_token).to eq([':', ':'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'class')])
        expect(lexer.next_token).to eq(['|', '|'])
        expect(lexer.next_token).to eq([:CHARACTER, Token.new(type: Token::Char, s_value: "'+'")])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'strings_1')])
        expect(lexer.next_token).to eq(['|', '|'])
        expect(lexer.next_token).to eq([:CHARACTER, Token.new(type: Token::Char, s_value: "'-'")])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'strings_2')])
        expect(lexer.next_token).to eq([';', ';'])
        expect(lexer.next_token).to eq([:IDENT_COLON, Token.new(type: Token::Ident, s_value: 'class')])
        expect(lexer.next_token).to eq([':', ':'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'keyword_class')])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'tSTRING')])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'keyword_end')])
        expect(lexer.next_token).to eq(['%prec', '%prec'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'tPLUS')])
        expect(lexer.next_token).to eq(['{', '{'])

        lexer.status = :c_declaration; lexer.end_symbol = '}'
        expect(lexer.next_token).to eq([:C_DECLARATION, Token.new(type: Token::User_code, s_value: " code 1 ")])
        lexer.status = :initial

        expect(lexer.next_token).to eq(['}', '}'])
        expect(lexer.next_token).to eq(['|', '|'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'keyword_class')])
        expect(lexer.next_token).to eq(['{', '{'])

        lexer.status = :c_declaration; lexer.end_symbol = '}'
        expect(lexer.next_token).to eq([:C_DECLARATION, Token.new(type: Token::User_code, s_value: " code 2 ")])
        lexer.status = :initial

        expect(lexer.next_token).to eq(['}', '}'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'tSTRING')])
        expect(lexer.next_token).to eq([:CHARACTER, Token.new(type: Token::Char, s_value: "'!'")])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'keyword_end')])
        expect(lexer.next_token).to eq(['{', '{'])

        lexer.status = :c_declaration; lexer.end_symbol = '}'
        expect(lexer.next_token).to eq([:C_DECLARATION, Token.new(type: Token::User_code, s_value: " code 3 ")])
        lexer.status = :initial

        expect(lexer.next_token).to eq(['}', '}'])
        expect(lexer.next_token).to eq(['%prec', '%prec'])
        expect(lexer.next_token).to eq([:STRING, '"="'])
        expect(lexer.next_token).to eq(['|', '|'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'keyword_class')])
        expect(lexer.next_token).to eq(['{', '{'])

        lexer.status = :c_declaration; lexer.end_symbol = '}'
        expect(lexer.next_token).to eq([:C_DECLARATION, Token.new(type: Token::User_code, s_value: " code 4 ")])
        lexer.status = :initial

        expect(lexer.next_token).to eq(['}', '}'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'tSTRING')])
        expect(lexer.next_token).to eq([:CHARACTER, Token.new(type: Token::Char, s_value: "'?'")])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'keyword_end')])
        expect(lexer.next_token).to eq(['{', '{'])

        lexer.status = :c_declaration; lexer.end_symbol = '}'
        expect(lexer.next_token).to eq([:C_DECLARATION, Token.new(type: Token::User_code, s_value: " code 5 ")])
        lexer.status = :initial

        expect(lexer.next_token).to eq(['}', '}'])
        expect(lexer.next_token).to eq(['%prec', '%prec'])
        expect(lexer.next_token).to eq([:CHARACTER, Token.new(type: Token::Char, s_value: "'>'")])
        expect(lexer.next_token).to eq([';', ';'])
        expect(lexer.next_token).to eq([:IDENT_COLON, Token.new(type: Token::Ident, s_value: 'strings_1')])
        expect(lexer.next_token).to eq([':', ':'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'string_1')])
        expect(lexer.next_token).to eq([';', ';'])
        expect(lexer.next_token).to eq([:IDENT_COLON, Token.new(type: Token::Ident, s_value: 'strings_2')])
        expect(lexer.next_token).to eq([':', ':'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'string_1')])
        expect(lexer.next_token).to eq(['|', '|'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'string_2')])
        expect(lexer.next_token).to eq([';', ';'])
        expect(lexer.next_token).to eq([:IDENT_COLON, Token.new(type: Token::Ident, s_value: 'string_1')])
        expect(lexer.next_token).to eq([':', ':'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'string')])
        expect(lexer.next_token).to eq([';', ';'])
        expect(lexer.next_token).to eq([:IDENT_COLON, Token.new(type: Token::Ident, s_value: 'string_2')])
        expect(lexer.next_token).to eq([':', ':'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'string')])
        expect(lexer.next_token).to eq([:CHARACTER, Token.new(type: Token::Char, s_value: "'+'")])
        expect(lexer.next_token).to eq([';', ';'])
        expect(lexer.next_token).to eq([:IDENT_COLON, Token.new(type: Token::Ident, s_value: 'string')])
        expect(lexer.next_token).to eq([':', ':'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'tSTRING')])
        expect(lexer.next_token).to eq([';', ';'])
        expect(lexer.next_token).to eq(['%%', '%%'])
        expect(lexer.next_token).to eq(nil)
      end
    end

    context 'nullable.y' do
      it do
        text = File.read(fixture_path("common/nullable.y"))
        lexer = Lrama::Lexer.new(text)

        expect(lexer.next_token).to eq(['%require', '%require'])
        expect(lexer.next_token).to eq([:STRING, '"3.0"'])
        expect(lexer.next_token).to eq(['%{', '%{'])

        lexer.status = :c_declaration; lexer.end_symbol = '%}'
        expect(lexer.next_token).to eq([:C_DECLARATION, Token.new(type: Token::User_code, s_value: "\n// Prologue\n")])
        lexer.status = :initial

        expect(lexer.next_token).to eq(['%}', '%}'])
        expect(lexer.next_token).to eq(['%token', '%token'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'tNUMBER')])
        expect(lexer.next_token).to eq(['%%', '%%'])
        expect(lexer.next_token).to eq([:IDENT_COLON, Token.new(type: Token::Ident, s_value: 'program')])
        expect(lexer.next_token).to eq([':', ':'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'stmt')])
        expect(lexer.next_token).to eq([';', ';'])
        expect(lexer.next_token).to eq([:IDENT_COLON, Token.new(type: Token::Ident, s_value: 'stmt')])
        expect(lexer.next_token).to eq([':', ':'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'expr')])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'opt_semicolon')])
        expect(lexer.next_token).to eq(['|', '|'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'opt_expr')])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'opt_colon')])
        expect(lexer.next_token).to eq(['|', '|'])
        expect(lexer.next_token).to eq([';', ';'])
        expect(lexer.next_token).to eq([:IDENT_COLON, Token.new(type: Token::Ident, s_value: 'expr')])
        expect(lexer.next_token).to eq([':', ':'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'tNUMBER')])
        expect(lexer.next_token).to eq([';', ';'])
        expect(lexer.next_token).to eq([:IDENT_COLON, Token.new(type: Token::Ident, s_value: 'opt_expr')])
        expect(lexer.next_token).to eq([':', ':'])
        expect(lexer.next_token).to eq(['|', '|'])
        expect(lexer.next_token).to eq([:IDENTIFIER, Token.new(type: Token::Ident, s_value: 'expr')])
        expect(lexer.next_token).to eq([';', ';'])
        expect(lexer.next_token).to eq([:IDENT_COLON, Token.new(type: Token::Ident, s_value: 'opt_semicolon')])
        expect(lexer.next_token).to eq([':', ':'])
        expect(lexer.next_token).to eq(['|', '|'])
        expect(lexer.next_token).to eq([:CHARACTER, Token.new(type: Token::Char, s_value: "';'")])
        expect(lexer.next_token).to eq([';', ';'])
        expect(lexer.next_token).to eq([:IDENT_COLON, Token.new(type: Token::Ident, s_value: 'opt_colon')])
        expect(lexer.next_token).to eq([':', ':'])
        expect(lexer.next_token).to eq(['|', '|'])
        expect(lexer.next_token).to eq([:CHARACTER, Token.new(type: Token::Char, s_value: "'.'")])
        expect(lexer.next_token).to eq([';', ';'])
        expect(lexer.next_token).to eq(['%%', '%%'])
        expect(lexer.next_token).to eq(nil)
      end
    end
  end
end
