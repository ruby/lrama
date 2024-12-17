class Lrama::Parser
  expect 0
  error_on_expect_mismatch

  token C_DECLARATION CHARACTER IDENT_COLON IDENTIFIER INTEGER STRING TAG

rule

  input: prologue_declaration* bison_declaration* "%%" rules_or_grammar_declaration+ epilogue_declaration?

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

  bison_declaration: grammar_declaration
                   | "%expect" INTEGER { @grammar.expect = val[1] }
                   | "%define" variable value { @grammar.define[val[1].s_value] = val[2]&.s_value }
                   | "%param" param+
                   | "%lex-param" param+
                       {
                         val[1].each {|token|
                           @grammar.lex_param = Grammar::Code::NoReferenceCode.new(type: :lex_param, token_code: token).token_code.s_value
                         }
                       }
                   | "%parse-param" param+
                       {
                         val[1].each {|token|
                           @grammar.parse_param = Grammar::Code::NoReferenceCode.new(type: :parse_param, token_code: token).token_code.s_value
                         }
                       }
                   | "%code" IDENTIFIER param
                       {
                         @grammar.add_percent_code(id: val[1], code: val[2])
                       }
                   | "%initial-action" param
                       {
                         @grammar.initial_action = Grammar::Code::InitialActionCode.new(type: :initial_action, token_code: val[1])
                       }
                   | "%no-stdlib" { @grammar.no_stdlib = true }
                   | "%locations" { @grammar.locations = true }
                   | bison_declaration ";"

  grammar_declaration: "%union" param
                         {
                           @grammar.set_union(
                             Grammar::Code::NoReferenceCode.new(type: :union, token_code: val[1]),
                             val[1].line
                           )
                         }
                     | symbol_declaration
                     | rule_declaration
                     | inline_declaration
                     | "%destructor" param (symbol | TAG)+
                         {
                           @grammar.add_destructor(
                             ident_or_tags: val[2].flatten,
                             token_code: val[1],
                             lineno: val[1].line
                           )
                         }
                     | "%printer" param (symbol | TAG)+
                         {
                           @grammar.add_printer(
                             ident_or_tags: val[2].flatten,
                             token_code: val[1],
                             lineno: val[1].line
                           )
                         }
                     | "%error-token" param (symbol | TAG)+
                         {
                           @grammar.add_error_token(
                             ident_or_tags: val[2].flatten,
                             token_code: val[1],
                             lineno: val[1].line
                           )
                         }
                     | "%after-shift" IDENTIFIER
                         {
                           @grammar.after_shift = val[1]
                         }
                     | "%before-reduce" IDENTIFIER
                         {
                           @grammar.before_reduce = val[1]
                         }
                     | "%after-reduce" IDENTIFIER
                         {
                           @grammar.after_reduce = val[1]
                         }
                     | "%after-shift-error-token" IDENTIFIER
                         {
                           @grammar.after_shift_error_token = val[1]
                         }
                     | "%after-pop-stack" IDENTIFIER
                         {
                           @grammar.after_pop_stack = val[1]
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

  token_declarations: TAG? token_declaration+
                        {
                          val[1].each {|token_declaration|
                            @grammar.add_term(id: token_declaration[0], alias_name: token_declaration[2], token_id: token_declaration[1], tag: val[0], replace: true)
                          }
                        }
                    | token_declarations TAG token_declaration+
                        {
                          val[2].each {|token_declaration|
                            @grammar.add_term(id: token_declaration[0], alias_name: token_declaration[2], token_id: token_declaration[1], tag: val[1], replace: true)
                          }
                        }

  token_declaration: id INTEGER? alias { result = val }

  rule_declaration: "%rule" IDENTIFIER "(" rule_args ")" TAG? ":" rule_rhs_list
                      {
                        rule = Grammar::ParameterizingRule::Rule.new(val[1].s_value, val[3], val[7], tag: val[5])
                        @grammar.add_parameterizing_rule(rule)
                      }

  inline_declaration: "%rule" "%inline" IDENT_COLON ":" rule_rhs_list
                      {
                        rule = Grammar::ParameterizingRule::Rule.new(val[2].s_value, [], val[4], is_inline: true)
                        @grammar.add_parameterizing_rule(rule)
                      }
                    | "%rule" "%inline" IDENTIFIER "(" rule_args ")" ":" rule_rhs_list
                      {
                        rule = Grammar::ParameterizingRule::Rule.new(val[2].s_value, val[4], val[7], is_inline: true)
                        @grammar.add_parameterizing_rule(rule)
                      }

  rule_args: IDENTIFIER { result = [val[0]] }
           | rule_args "," IDENTIFIER { result = val[0].append(val[2]) }

  rule_rhs_list: rule_rhs
                {
                  builder = val[0]
                  result = [builder]
                }
          | rule_rhs_list "|" rule_rhs
                {
                  builder = val[2]
                  result = val[0].append(builder)
                }

  rule_rhs: "%empty"?
            {
              reset_precs
              result = Grammar::ParameterizingRule::Rhs.new
            }
          | rule_rhs symbol named_ref?
            {
              token = val[1]
              token.alias_name = val[2]
              builder = val[0]
              builder.symbols << token
              result = builder
            }
          | rule_rhs symbol parameterizing_suffix
              {
                builder = val[0]
                builder.symbols << Lrama::Lexer::Token::InstantiateRule.new(s_value: val[2], location: @lexer.location, args: [val[1]])
                result = builder
              }
          | rule_rhs IDENTIFIER "(" parameterizing_args ")" TAG?
              {
                builder = val[0]
                builder.symbols << Lrama::Lexer::Token::InstantiateRule.new(s_value: val[1].s_value, location: @lexer.location, args: val[3], lhs_tag: val[5])
                result = builder
              }
          | rule_rhs midrule_action named_ref?
            {
              user_code = val[1]
              user_code.alias_name = val[2]
              builder = val[0]
              builder.user_code = user_code
              result = builder
            }
          | rule_rhs "%prec" symbol
            {
              sym = @grammar.find_symbol_by_id!(val[2])
              @prec_seen = true
              builder = val[0]
              builder.precedence_sym = sym
              result = builder
            }

  alias: string_as_id? { result = val[0].s_value if val[0] }

  symbol_declarations: symbol+ { result = [{tag: nil, tokens: val[0]}] }
                     | TAG symbol+ { result = [{tag: val[0], tokens: val[1]}] }
                     | symbol_declarations TAG symbol+ { result = val[0].append({tag: val[1], tokens: val[2]}) }

  symbol: id
        | string_as_id

  param: "{" {
               begin_c_declaration("}")
             }
         C_DECLARATION
             {
               end_c_declaration
             }
         "}"
             {
               result = val[2]
             }

  token_declarations_for_precedence: id+ { result = [{tag: nil, tokens: val[0]}] }
                                   | TAG id+ { result = [{tag: val[0], tokens: val[1]}] }
                                   | id TAG id+ { result = val[0].append({tag: val[1], tokens: val[2]}) }

  id: IDENTIFIER { on_action_error("ident after %prec", val[0]) if @prec_seen }
    | CHARACTER { on_action_error("char after %prec", val[0]) if @prec_seen }


  rules_or_grammar_declaration: rules ";"?
                              | grammar_declaration ";"

  rules: IDENT_COLON named_ref? ":" rhs_list
           {
             lhs = val[0]
             lhs.alias_name = val[1]
             val[3].each do |builder|
               builder.lhs = lhs
               builder.complete_input
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

  rhs: "%empty"?
         {
           reset_precs
           result = @grammar.create_rule_builder(@rule_counter, @midrule_action_counter)
         }
     | rhs symbol named_ref?
         {
           token = val[1]
           token.alias_name = val[2]
           builder = val[0]
           builder.add_rhs(token)
           result = builder
         }
     | rhs symbol parameterizing_suffix named_ref? TAG?
         {
           token = Lrama::Lexer::Token::InstantiateRule.new(s_value: val[2], alias_name: val[3], location: @lexer.location, args: [val[1]], lhs_tag: val[4])
           builder = val[0]
           builder.add_rhs(token)
           builder.line = val[1].first_line
           result = builder
         }
     | rhs IDENTIFIER "(" parameterizing_args ")" named_ref? TAG?
         {
           token = Lrama::Lexer::Token::InstantiateRule.new(s_value: val[1].s_value, alias_name: val[5], location: @lexer.location, args: val[3], lhs_tag: val[6])
           builder = val[0]
           builder.add_rhs(token)
           builder.line = val[1].first_line
           result = builder
         }
     | rhs midrule_action named_ref? TAG?
         {
           user_code = val[1]
           user_code.alias_name = val[2]
           user_code.tag = val[3]
           builder = val[0]
           builder.user_code = user_code
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

  parameterizing_suffix: "?" { result = "option" }
                       | "+" { result = "nonempty_list" }
                       | "*" { result = "list" }

  parameterizing_args: symbol { result = [val[0]] }
                     | parameterizing_args ',' symbol { result = val[0].append(val[2]) }
                     | symbol parameterizing_suffix { result = [Lrama::Lexer::Token::InstantiateRule.new(s_value: val[1].s_value, location: @lexer.location, args: val[0])] }
                     | IDENTIFIER "(" parameterizing_args ")" { result = [Lrama::Lexer::Token::InstantiateRule.new(s_value: val[0].s_value, location: @lexer.location, args: val[2])] }

  midrule_action: "{"
                    {
                      if @prec_seen
                        on_action_error("multiple User_code after %prec", val[0])  if @code_after_prec
                        @code_after_prec = true
                      end
                      begin_c_declaration("}")
                    }
                  C_DECLARATION
                    {
                      end_c_declaration
                    }
                  "}"
                    {
                      result = val[2]
                    }

  named_ref: '[' IDENTIFIER ']' { result = val[1].s_value }

  epilogue_declaration: "%%"
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

  string_as_id: STRING { result = Lrama::Lexer::Token::Ident.new(s_value: val[0]) }
end

---- inner

include Lrama::Report::Duration

def initialize(text, path, debug = false, define = {})
  @grammar_file = Lrama::Lexer::GrammarFile.new(path, text)
  @yydebug = debug
  @rule_counter = Lrama::Grammar::Counter.new(0)
  @midrule_action_counter = Lrama::Grammar::Counter.new(1)
  @define = define
end

def parse
  report_duration(:parse) do
    @lexer = Lrama::Lexer.new(@grammar_file)
    @grammar = Lrama::Grammar.new(@rule_counter, @define)
    @precedence_number = 0
    reset_precs
    do_parse
    @grammar
  end
end

def next_token
  @lexer.next_token
end

def on_error(error_token_id, error_value, value_stack)
  if error_value.is_a?(Lrama::Lexer::Token)
    location = error_value.location
    value = "'#{error_value.s_value}'"
  else
    location = @lexer.location
    value = error_value.inspect
  end

  error_message = "parse error on value #{value} (#{token_to_str(error_token_id) || '?'})"

  raise_parse_error(error_message, location)
end

def on_action_error(error_message, error_value)
  if error_value.is_a?(Lrama::Lexer::Token)
    location = error_value.location
  else
    location = @lexer.location
  end

  raise_parse_error(error_message, location)
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

def raise_parse_error(error_message, location)
  raise ParseError, location.generate_error_message(error_message)
end
