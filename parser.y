class Lrama::NewParser
rule
  input: prologue_declarations "%%" grammar epilogue_opt { result = Lrama::Grammar.new; result.prologue = val[0] }

  prologue_declarations: /* empty */ { result = "" }
                       | prologue_declarations prologue_declaration { result = val[0] + val[1] }

  prologue_declaration: grammar_declaration
                      | "%{" {@lexer.status = :c_declaration; @lexer.end_symbol = '%}'} C_DECLARATION {@lexer.status = :initial; @lexer.end_symbol = nil} "%}" { result = val[2] }
                      | "%expect" INTEGER
                      | "%define" variable value
                      | "%require" STRING
                      | "%param" params
                      | "%lex-param" params
                      | "%parse-param" params
                      | "%initial-action" "{" {@lexer.status = :c_declaration; @lexer.end_symbol = '}'} C_DECLARATION {@lexer.status = :initial; @lexer.end_symbol = nil} "}"
                      | ";"

  grammar_declaration: "%union" "{" {@lexer.status = :c_declaration; @lexer.end_symbol = '}'} C_DECLARATION {@lexer.status = :initial; @lexer.end_symbol = nil} "}"
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
  @grammar = do_parse.tap { p _1 }
end

def next_token
  @lexer.next_token
end
