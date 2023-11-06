class Lrama::Parser
  expect 7

  token C_DECLARATION CHARACTER IDENT_COLON IDENTIFIER INTEGER STRING TAG

rule

  input: prologue_declarations bison_declarations "%%" grammar epilogue_opt

  prologue_declarations: # empty
                       | prologue_declarations prologue_declaration

  prologue_declaration: "%{"
                          {
                            begin_c_declaration("%}")
                            @grammar.prologue_first_lineno = @lexer.line
                          }
                        C_DECLARATION
                          {
                            end_c_declaration
                          }
                        "%}"
                          {
                            @grammar.prologue = val[2].s_value
                          }
                      | "%require" STRING

  bison_declarations: /* empty */ { result = "" }
                    | bison_declarations bison_declaration

  bison_declaration: grammar_declaration
                   | "%expect" INTEGER { @grammar.expect = val[1] }
                   | "%define" variable value
                   | "%require" STRING
                   | "%param" params
                   | "%lex-param" params
                       {
                         val[1].each {|token|
                           @grammar.lex_param = Grammar::Code::NoReferenceCode.new(type: :lex_param, token_code: token).token_code.s_value
                         }
                       }
                   | "%parse-param" params
                       {
                         val[1].each {|token|
                           @grammar.parse_param = Grammar::Code::NoReferenceCode.new(type: :parse_param, token_code: token).token_code.s_value
                         }
                       }
                   | "%code" IDENTIFIER "{"
                       {
                         begin_c_declaration("}")
                       }
                     C_DECLARATION
                       {
                         end_c_declaration
                       }
                     "}"
                       {
                         @grammar.add_percent_code(id: val[1], code: val[4])
                       }
                   | "%initial-action" "{"
                       {
                         begin_c_declaration("}")
                       }
                     C_DECLARATION
                       {
                         end_c_declaration
                       }
                     "}"
                       {
                         @grammar.initial_action = Grammar::Code::InitialActionCode.new(type: :initial_action, token_code: val[3])
                       }
                   | ";"

  grammar_declaration: "%union" "{"
                         {
                           begin_c_declaration("}")
                         }
                       C_DECLARATION
                         {
                           end_c_declaration
                         }
                       "}"
                         {
                           @grammar.set_union(
                             Grammar::Code::NoReferenceCode.new(type: :union, token_code: val[3]),
                             val[3].line
                           )
                         }
                     | symbol_declaration
                     | "%destructor" "{"
                         {
                           begin_c_declaration("}")
                         }
                       C_DECLARATION
                         {
                           end_c_declaration
                         }
                       "}" generic_symlist
                     | "%printer" "{"
                         {
                           begin_c_declaration("}")
                         }
                       C_DECLARATION
                         {
                           end_c_declaration
                         }
                       "}" generic_symlist
                         {
                           @grammar.add_printer(
                             ident_or_tags: val[6],
                             token_code: val[3],
                             lineno: val[3].line
                           )
                         }
                     | "%error-token" "{"
                         {
                           begin_c_declaration("}")
                         }
                       C_DECLARATION
                         {
                           end_c_declaration
                         }
                       "}" generic_symlist
                         {
                           @grammar.add_error_token(
                             ident_or_tags: val[6],
                             token_code: val[3],
                             lineno: val[3].line
                           )
                         }

  symbol_declaration: "%token" token_declarations
                    | "%type" symbol_declarations
                        {
                          val[1].each {|hash|
                            hash[:tokens].each {|id|
                              @grammar.add_type(id: id, tag: hash[:tag])
                            }
                          }
                        }
                    | "%left" token_declarations_for_precedence
                        {
                          val[1].each {|hash|
                            hash[:tokens].each {|id|
                              sym = @grammar.add_term(id: id)
                              @grammar.add_left(sym, @precedence_number)
                            }
                          }
                          @precedence_number += 1
                        }
                    | "%right" token_declarations_for_precedence
                        {
                          val[1].each {|hash|
                            hash[:tokens].each {|id|
                              sym = @grammar.add_term(id: id)
                              @grammar.add_right(sym, @precedence_number)
                            }
                          }
                          @precedence_number += 1
                        }
                    | "%precedence" token_declarations_for_precedence
                        {
                          val[1].each {|hash|
                            hash[:tokens].each {|id|
                              sym = @grammar.add_term(id: id)
                              @grammar.add_precedence(sym, @precedence_number)
                            }
                          }
                          @precedence_number += 1
                        }
                    | "%nonassoc" token_declarations_for_precedence
                        {
                          val[1].each {|hash|
                            hash[:tokens].each {|id|
                              sym = @grammar.add_term(id: id)
                              @grammar.add_nonassoc(sym, @precedence_number)
                            }
                          }
                          @precedence_number += 1
                        }

  token_declarations: token_declaration_list
                        {
                          val[0].each {|token_declaration|
                            @grammar.add_term(id: token_declaration[0], alias_name: token_declaration[2], token_id: token_declaration[1], tag: nil, replace: true)
                          }
                        }
                    | TAG token_declaration_list
                        {
                          val[1].each {|token_declaration|
                            @grammar.add_term(id: token_declaration[0], alias_name: token_declaration[2], token_id: token_declaration[1], tag: val[0], replace: true)
                          }
                        }
                    | token_declarations TAG token_declaration_list
                        {
                          val[2].each {|token_declaration|
                            @grammar.add_term(id: token_declaration[0], alias_name: token_declaration[2], token_id: token_declaration[1], tag: val[1], replace: true)
                          }
                        }

  token_declaration_list: token_declaration { result = [val[0]] }
                        | token_declaration_list token_declaration { result = val[0].append(val[1]) }

  token_declaration: id int_opt alias { result = val }

  int_opt: # empty
         | INTEGER

  alias: # empty
       | STRING # TODO: change this to string_as_id

  symbol_declarations: symbol_declaration_list
                         {
                           result = [{tag: nil, tokens: val[0]}]
                         }
                     | TAG symbol_declaration_list
                         {
                           result = [{tag: val[0], tokens: val[1]}]
                         }
                     | symbol_declarations TAG symbol_declaration_list
                       {
                         result = val[0].append({tag: val[1], tokens: val[2]})
                       }

  symbol_declaration_list: symbol { result = [val[0]] }
                         | symbol_declaration_list symbol { result = val[0].append(val[1]) }

  symbol: id
        | string_as_id

  params: params "{"
            {
              begin_c_declaration("}")
            }
          C_DECLARATION
            {
              end_c_declaration
            }
          "}"
            {
              result = val[0].append(val[3])
            }
        | "{"
            {
              begin_c_declaration("}")
            }
          C_DECLARATION
            {
              end_c_declaration
            }
          "}"
            {
              result = [val[2]]
            }

  token_declarations_for_precedence: token_declaration_list_for_precedence
                                       {
                                         result = [{tag: nil, tokens: val[0]}]
                                       }
                                   | TAG token_declaration_list_for_precedence
                                       {
                                         result = [{tag: val[0], tokens: val[1]}]
                                       }
                                   | token_declarations_for_precedence token_declaration_list_for_precedence
                                       {
                                         result = val[0].append({tag: nil, tokens: val[1]})
                                       }

  token_declaration_list_for_precedence: token_declaration_for_precedence { result = [val[0]] }
                                       | token_declaration_list_for_precedence token_declaration_for_precedence { result = val[0].append(val[1]) }

  token_declaration_for_precedence: id

  id: IDENTIFIER { raise "Ident after %prec" if @prec_seen }
    | CHARACTER { raise "Char after %prec" if @prec_seen }

  grammar: rules_or_grammar_declaration
         | grammar rules_or_grammar_declaration

  rules_or_grammar_declaration: rules
                              | grammar_declaration ";"

  rules: id_colon named_ref_opt ":" rhs_list
           {
             lhs = val[0]
             lhs.alias_name = val[1]
             val[3].each do |builder|
               builder.lhs = lhs
               builder.freeze_rhs
               @grammar.add_rule_builder(builder)
             end
           }

  rhs_list: rhs
              {
                builder = val[0]
                if !builder.line
                  builder.line = @lexer.line - 1
                end
                result = [builder]
              }
          | rhs_list "|" rhs
              {
                builder = val[2]
                if !builder.line
                  builder.line = @lexer.line - 1
                end
                result = val[0].append(builder)
              }
          | rhs_list ";"

  rhs: /* empty */
         {
           reset_precs
           result = Grammar::RuleBuilder.new
         }
     | "%empty"
         {
           reset_precs
           result = Grammar::RuleBuilder.new
         }
     | rhs symbol named_ref_opt
         {
           token = val[1]
           token.alias_name = val[2]
           builder = val[0]
           builder.add_rhs(token)
           result = builder
         }
     | rhs parameterizing_suffix
         {
           token = Lrama::Lexer::Token::Parameterizing.new(s_value: val[1])
           builder = val[0]
           builder.add_rhs(token)
           result = builder
         }
     | parameterizing_prefix rhs ")"
         {
           token = Lrama::Lexer::Token::Parameterizing.new(s_value: val[0].chop)
           builder = val[1]
           builder.add_rhs(token)
           result = builder
         }
     | parameterizing_separated_prefix symbol "," rhs ")"
        {
          token = Lrama::Lexer::Token::Parameterizing.new(s_value: val[0].chop)
          builder = val[3]
          builder.add_rhs(token)
          builder.add_rhs(val[1])
          result = builder
        }
     | rhs "{"
         {
           if @prec_seen
             raise "Multiple User_code after %prec" if @code_after_prec
             @code_after_prec = true
           end
           begin_c_declaration("}")
         }
       C_DECLARATION
         {
           end_c_declaration
         }
       "}" named_ref_opt
         {
           token = val[3]
           token.alias_name = val[6]
           builder = val[0]
           builder.user_code = token
           result = builder
         }
     | rhs "%prec" symbol
         {
           sym = @grammar.find_symbol_by_id!(val[2])
           @prec_seen = true
           builder = val[0]
           builder.precedence_sym = sym
           result = builder
         }

  parameterizing_prefix: "option("
                       | "nonempty_list("
                       | "list("

  parameterizing_separated_prefix: "separated_nonempty_list("
                                 | "separated_list("

  parameterizing_suffix: "?"
                       | "+"
                       | "*"

  named_ref_opt: # empty
               | '[' IDENTIFIER ']' { result = val[1].s_value }

  id_colon: IDENT_COLON

  epilogue_opt: # empty
              | "%%"
                  {
                    begin_c_declaration('\Z')
                    @grammar.epilogue_first_lineno = @lexer.line + 1
                  }
                C_DECLARATION
                  {
                    end_c_declaration
                    @grammar.epilogue = val[2].s_value
                  }

  variable: id

  value: # empty
       | IDENTIFIER
       | STRING
       | "{...}"

  generic_symlist: generic_symlist_item { result = [val[0]] }
                 | generic_symlist generic_symlist_item { result = val[0].append(val[1]) }

  generic_symlist_item: symbol
                      | TAG

  string_as_id: STRING { result = Lrama::Lexer::Token::Ident.new(s_value: val[0]) }
end

---- inner

include Lrama::Report::Duration

def initialize(text, path, debug = false)
  @text = text
  @path = path
  @yydebug = debug
end

def parse
  report_duration(:parse) do
    @lexer = Lrama::Lexer.new(@text)
    @grammar = Lrama::Grammar.new
    @precedence_number = 0
    reset_precs
    do_parse
    @grammar.prepare
    @grammar.compute_nullable
    @grammar.compute_first_set
    @grammar.validate!
    @grammar
  end
end

def next_token
  @lexer.next_token
end

def on_error(error_token_id, error_value, value_stack)
  if error_value.is_a?(Lrama::Lexer::Token)
    line = error_value.first_line
    first_column = error_value.first_column
    last_column = error_value.last_column
    value = "'#{error_value.s_value}'"
  else
    line = @lexer.line
    first_column = @lexer.head_column
    last_column = @lexer.column
    value = error_value.inspect
  end

  raise ParseError, <<~ERROR
    #{@path}:#{line}:#{first_column}: parse error on value #{value} (#{token_to_str(error_token_id) || '?'})
    #{@text.split("\n")[line - 1]}
    #{carrets(first_column, last_column)}
  ERROR
end

private

def reset_precs
  @prec_seen = false
  @code_after_prec = false
end

def begin_c_declaration(end_symbol)
  @lexer.status = :c_declaration
  @lexer.end_symbol = end_symbol
end

def end_c_declaration
  @lexer.status = :initial
  @lexer.end_symbol = nil
end

def carrets(first_column, last_column)
  ' ' * (first_column + 1) + '^' * (last_column - first_column)
end
