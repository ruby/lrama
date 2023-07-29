class Lrama::NewParser
rule
  input: prologue_declaration bison_declarations "%%" grammar epilogue_opt

  prologue_declaration: /* empty */
                      | "%{" {@lexer.status = :c_declaration; @lexer.end_symbol = '%}'} C_DECLARATION {@lexer.status = :initial; @lexer.end_symbol = nil} "%}" { @grammar.prologue = val[2].lstrip }

  bison_declarations: /* empty */ { result = "" }
                    | bison_declarations bison_declaration

  bison_declaration: grammar_declaration
                   | "%expect" INTEGER
                   | "%define" variable value
                   | "%require" STRING
                   | "%param" params
                   | "%lex-param" params
                   | "%parse-param" params
                   | "%initial-action" "{" {@lexer.status = :c_declaration; @lexer.end_symbol = '}'} C_DECLARATION {@lexer.status = :initial; @lexer.end_symbol = nil} "}"
                   | ";"

  grammar_declaration: "%union" "{" {@lexer.status = :c_declaration; @lexer.end_symbol = '}'} C_DECLARATION {@lexer.status = :initial; @lexer.end_symbol = nil} "}" { token = Lrama::Lexer::Token.new(type: Lrama::Lexer::Token::User_code, s_value: "{#{val[3]}}"); token.references = []; @grammar.set_union(@grammar.build_code(:union, token), nil) }
                     | symbol_declaration
                     | code_props_type "{" {@lexer.status = :c_declaration; @lexer.end_symbol = '}'} C_DECLARATION {@lexer.status = :initial; @lexer.end_symbol = nil} "}" generic_symlist

  code_props_type: "%destructor"
                 | "%printer"

  symbol_declaration: "%token" token_declarations
                    | "%type" symbol_declarations
                    | precedence_declarator token_declarations_for_precedence

  token_declarations: token_declaration_list
                    | TAG token_declaration_list
                    | token_declarations TAG token_declaration_list

  token_declaration_list: token_declaration
                        | token_declaration_list token_declaration

  token_declaration: id int_opt alias

  int_opt: # empty
         | INTEGER

  alias: # empty
       | string_as_id
       | STRING

  symbol_declarations: symbol_declaration_list
                     | TAG symbol_declaration_list
                     | symbol_declarations symbol_declaration_list

  symbol_declaration_list: symbol
                         | symbol_declaration_list symbol

  symbol: id

  params: params "{" {@lexer.status = :c_declaration; @lexer.end_symbol = '}'} C_DECLARATION {@lexer.status = :initial; @lexer.end_symbol = nil} "}"
        | "{" {@lexer.status = :c_declaration; @lexer.end_symbol = '}'} C_DECLARATION {@lexer.status = :initial; @lexer.end_symbol = nil} "}"

  precedence_declarator: "%left"
                       | "%right"
                       | "%nonassoc"

  token_declarations_for_precedence: token_declaration_list_for_precedence
                                   | TAG token_declaration_list_for_precedence
                                   | token_declarations_for_precedence token_declaration_list_for_precedence

  token_declaration_list_for_precedence: token_declaration_for_precedence
                                       | token_declaration_list_for_precedence token_declaration_for_precedence

  token_declaration_for_precedence: id

  id: IDENTIFIER
    | CHARACTER

  grammar: rules_or_grammar_declaration
         | grammar rules_or_grammar_declaration

  rules_or_grammar_declaration: rules
                              | grammar_declaration ";"

  rules: id_colon ":" rhs_list

  rhs_list: rhs
          | rhs_list "|" rhs
          | rhs_list ";"

  rhs: # empty
     | rhs symbol
     | rhs "{" {@lexer.status = :c_declaration; @lexer.end_symbol = '}'} C_DECLARATION {@lexer.status = :initial; @lexer.end_symbol = nil} "}"
     | rhs "%prec" symbol

  id_colon: id

  epilogue_opt: # empty
              | "%%" {@lexer.status = :c_declaration; @lexer.end_symbol = '\Z'} C_DECLARATION {@lexer.status = :initial; @lexer.end_symbol = nil}

  variable: id

  value: # empty
       | IDENTIFIER
       | STRING
       | "{...}"

  generic_symlist: generic_symlist_item
                 | generic_symlist generic_symlist_item

  generic_symlist_item: symbol
                      | tag
  tag: TAG
     | "<*>"
     | "<>"

end

---- inner

def initialize(text)
  @text = text
  @yydebug = true
end

def parse
  @lexer = Lrama::NewLexer.new(@text)
  @grammar = Lrama::Grammar.new
  do_parse
  @grammar
end

def next_token
  @lexer.next_token
end
