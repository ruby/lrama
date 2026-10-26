class Lrama::Parser
  expect 0
  error_on_expect_mismatch

  token C_DECLARATION CHARACTER IDENT_COLON IDENTIFIER INTEGER STRING TAG

rule

  input: prologue_declaration* bison_declaration* "%%" rules_or_grammar_declaration+ epilogue_declaration?
        {
          ary = []
          ary.concat(val[0]) if val[0]
          ary.concat(val[1]) if val[1]
          ary.concat(val[3].flatten)
          ary.append(val[4]) if val[4]
          result = ary
        }

  prologue_declaration:
      "%{"
        {
          begin_c_declaration("%}")
        }
      C_DECLARATION
        {
          end_c_declaration
        }
      "%}"
        {
          result = Grammar::Node::PrologueDecl.new(code: val[2], location: merge_locations(val[0].loc, val[4].loc))
        }
    | "%require" STRING
        {
          result = Grammar::Node::RequireDecl.new(location: merge_locations(val[0].loc, val[1].loc))
        }

  bison_declaration:
      parser_option ";"*
    | grammar_declaration ";"*

  parser_option:
      "%expect" INTEGER
        {
          result = Grammar::Node::ExpectDecl.new(
            number: val[1].s_value,
            location: merge_locations(val[0], val[1])
          )
        }
    | "%define" variable value
        {
          result = Grammar::Node::DefineDecl.new(
            variable: val[1].s_value,
            value: val[2]&.s_value,
            location: merge_locations(val[0].loc, val[1].loc, val[2]&.loc)
          )
        }
    | "%define" variable "{" value "}"
        {
          result = Grammar::Node::DefineDecl.new(
            variable: val[1].s_value,
            value: val[3]&.s_value,
            location: merge_locations(val[0].loc, val[4].loc)
          )
        }
    | "%param" param+
    | "%lex-param" param+
        {
          result = Grammar::Node::LexParamDecl.new(
            params: val[1],
            location: merge_locations(val[0].loc, val[1].last.loc)
          )
        }
    | "%parse-param" param+
        {
          result = Grammar::Node::ParseParamDecl.new(
            params: val[1],
            location: merge_locations(val[0].loc, val[1].last.loc)
          )
        }
    | "%code" IDENTIFIER param
        {
          result = Grammar::Node::CodeDecl.new(
            id: val[1],
            code: val[2],
            location: merge_locations(val[0].loc, val[2].loc)
          )
        }
    | "%initial-action" param
        {
          result = Grammar::Node::InitialActionDecl.new(
            code: val[1],
            location: merge_locations(val[0].loc, val[1].loc)
          )
        }
    | "%no-stdlib"
        {
          result = Grammar::Node::NoStdlibDecl.new(
            location: val[0].loc
          )
        }
    | "%locations"
        {
          result = Grammar::Node::LocationsDecl.new(
            location: val[0].loc
          )
        }

  grammar_declaration:
      symbol_declaration
    | rule_declaration
    | inline_declaration
    | "%union" param
        {
          result = Grammar::Node::UnionDecl.new(
            code: val[1],
            location: val[1].loc
          )
        }
    | "%destructor" param (symbol | TAG)+
        {
          result = Grammar::Node::DestructorDecl.new(
            ident_or_tags: val[2].flatten,
            code: val[1],
            location: val[1].loc
          )
        }
    | "%printer" param (symbol | TAG)+
        {
          result = Grammar::Node::PrinterDecl.new(
            ident_or_tags: val[2].flatten,
            code: val[1],
            location: val[1].loc
          )
        }
    | "%error-token" param (symbol | TAG)+
        {
          result = Grammar::Node::ErrorTokenDecl.new(
            ident_or_tags: val[2].flatten,
            code: val[1],
            location: val[1].loc
          )
        }
    | "%after-shift" IDENTIFIER
        {
          result = Grammar::Node::AfterShiftDecl.new(
            id: val[1],
            location: merge_locations(val[0].loc, val[1].loc)
          )
        }
    | "%before-reduce" IDENTIFIER
        {
          result = Grammar::Node::BeforeReduceDecl.new(
            id: val[1],
            location: merge_locations(val[0].loc, val[1].loc)
          )
        }
    | "%after-reduce" IDENTIFIER
        {
          result = Grammar::Node::AfterReduceDecl.new(
            id: val[1],
            location: merge_locations(val[0].loc, val[1].loc)
          )
        }
    | "%after-shift-error-token" IDENTIFIER
        {
          result = Grammar::Node::AfterShiftErrorTokenDecl.new(
            id: val[1],
            location: merge_locations(val[0].loc, val[1].loc)
          )
        }
    | "%after-pop-stack" IDENTIFIER
        {
          result = Grammar::Node::AfterPopStackDecl.new(
            id: val[1],
            location: merge_locations(val[0].loc, val[1].loc)
          )
        }

  symbol_declaration:
      "%token" token_declarations
        {
          result = Grammar::Node::TokenDecl.new(tokens: val[1], location: merge_locations(val[0].loc, val[1].last.loc))
        }
    | "%type" symbol_declarations
        {
          result = Grammar::Node::TypeDecl.new(
            symbols: val[1],
            location: merge_locations(*val[1].map(&:loc))
          )
        }
    | "%nterm" symbol_declarations
        {
          result = Grammar::Node::NtermDecl.new(
            symbols: val[1],
            location: merge_locations(*val[1].map(&:loc))
          )
        }
    | "%left" token_declarations_for_precedence
        {
          result = Grammar::Node::PrecedenceDecl.new(
            type: :left, tokens: val[1], number: @precedence_number,
            location: merge_locations(val[0].loc, val[1].last.loc)
          )
          @precedence_number += 1
        }
    | "%right" token_declarations_for_precedence
        {
          result = Grammar::Node::PrecedenceDecl.new(
            type: :right, tokens: val[1], number: @precedence_number,
            location: merge_locations(val[0].loc, val[1].last.loc)
          )
          @precedence_number += 1
        }
    | "%precedence" token_declarations_for_precedence
        {
          result = Grammar::Node::PrecedenceDecl.new(
            type: :precedence, tokens: val[1], number: @precedence_number,
            location: merge_locations(val[0].loc, val[1].last.loc)
          )
          @precedence_number += 1
        }
    | "%nonassoc" token_declarations_for_precedence
        {
          result = Grammar::Node::PrecedenceDecl.new(
            type: :nonassoc, tokens: val[1], number: @precedence_number,
            location: merge_locations(val[0].loc, val[1].last.loc)
          )
          @precedence_number += 1
        }
    | "%start" IDENTIFIER
        {
          result = Grammar::Node::StartDecl.new(
            id: val[1],
            location: merge_locations(val[0].loc, val[1].loc)
          )
        }

  token_declarations:
      TAG? token_declaration+
        {
          val[1].each {|token|
            token.tag = val[0]
          }
          result = val[1]
        }
    | token_declarations TAG token_declaration+
        {
          val[2].each {|token|
            token.tag = val[1]
          }
          result = val[0].concat(val[2])
        }

  token_declaration: id INTEGER? alias
        {
          result = Grammar::Node::Token.new(
            id: val[0], token_id: val[1]&.s_value, alias_name: val[2]&.s_value,
            location: merge_locations(val[0].loc, val[1]&.loc, val[2]&.loc)
          )
        }

  rule_declaration:
      "%rule" IDENTIFIER "(" rule_args ")" TAG? ":" rule_rhs_list
        {
          result = Grammar::Node::ParameterizedRule.new(
            name: val[1].s_value, parameters: val[3], tag: val[5],
            rhs_list: val[7], is_inline: false,
            location: merge_locations(val[0].loc, val[6].loc, *val[7].flatten.map(&:loc))
          )
        }

  inline_declaration:
      "%rule" "%inline" IDENT_COLON ":" rule_rhs_list
        {
          result = Grammar::Node::ParameterizedRule.new(
            name: val[2].s_value, parameters: [],
            rhs_list: val[4], is_inline: true,
            location: merge_locations(val[0].loc, val[3].loc, *val[4].flatten.map(&:loc))
          )
        }
    | "%rule" "%inline" IDENTIFIER "(" rule_args ")" ":" rule_rhs_list
        {
          result = Grammar::Node::ParameterizedRule.new(
            name: val[2].s_value, parameters: val[4],
            rhs_list: val[7], is_inline: true,
            location: merge_locations(val[0].loc, val[6].loc, *val[7].flatten.map(&:loc))
          )
        }

  rule_args:
      IDENTIFIER { result = [val[0]] }
    | rule_args "," IDENTIFIER { result = val[0].append(val[2]) }

  rule_rhs_list:
      rule_rhs
        {
          result = [val[0]]
        }
    | rule_rhs_list "|" rule_rhs
        {
          result = val[0].append(val[2])
        }

  rule_rhs:
      "%empty"?
        {
          reset_precs
          result = []
        }
    | rule_rhs symbol named_ref?
        {
          on_action_error("intermediate %prec in a rule", val[1]) if @trailing_prec_seen
          node = Grammar::Node::RuleRhs::Symbol.new(
            token: val[1], alias_name: val[2],
            location: val[1].loc
          )
          result.append(node)
        }
    | rule_rhs symbol parameterized_suffix
        {
          on_action_error("intermediate %prec in a rule", val[1]) if @trailing_prec_seen
          argument = Grammar::Node::RuleRhs::Symbol.new(
            token: val[1], location: val[1].loc
          )
          node = Grammar::Node::RuleRhs::InstantiateRule.new(
            name: parameterized_rule_name(val[2]), args: [argument],
            location: val[1].loc
          )
          result.append(node)
        }
    | rule_rhs IDENTIFIER "(" parameterized_args ")" named_ref? TAG?
        {
          on_action_error("intermediate %prec in a rule", val[1]) if @trailing_prec_seen
          node = Grammar::Node::RuleRhs::InstantiateRule.new(
            name: val[1].s_value, args: val[3],
            alias_name: val[5], lhs_tag: val[6],
            location: merge_locations(val[1].loc, val[4], val[6]&.loc)
          )
          result.append(node)
        }
    | rule_rhs action named_ref?
        {
          node = Grammar::Node::RuleRhs::Action.new(
            code: val[1], alias_name: val[2],
            location: val[1].loc
          )
          result.append(node)
        }
    | rule_rhs "%prec" symbol
        {
          on_action_error("multiple %prec in a rule", val[0]) if prec_seen?
          if val[0].empty?
            @opening_prec_seen = true
          else
            @trailing_prec_seen = true
          end

          node = Grammar::Node::RuleRhs::Prec.new(
            token: val[2],
            location: val[2].loc
          )
          result.append(node)
        }

  alias: string_as_id?

  symbol_declarations:
      TAG? symbol+
        {
          result = val[1].map do |id|
            Grammar::Node::Symbol.new(
              id: id, tag: val[0],
              location: id.loc
            )
          end
        }
    | symbol_declarations TAG symbol+
        {
          syms = val[2].map do |id|
            Grammar::Node::Symbol.new(
              id: id, tag: val[1],
              location: id.loc
            )
          end
          result = val[0].concat(syms)
        }

  symbol:
      id
    | string_as_id

  param:
      "{"
        {
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

  token_declarations_for_precedence:
      id+
        {
          result = val[0].map do |id|
            Grammar::Node::Token.new(
              id: id,
              location: id.loc
            )
          end
        }
    | (TAG id+)+
        {
          result = val[0].flat_map do |tag, ids|
            ids.map do |id|
              Grammar::Node::Token.new(
                id: id,
                tag: tag,
                location: id.loc
              )
            end
          end
        }
    | id+ TAG id+
        {
          # result = [{tag: nil, tokens: val[0]}, {tag: val[1], tokens: val[2]}]
          result = val[0].map do |id|
            Grammar::Node::Token.new(
              id: id,
              location: id.loc
            )
            end + val[2].map do |id|
            Grammar::Node::Token.new(
              id: id,
              tag: val[1],
              location: id.loc
            )
            end
        }

  id:
      IDENTIFIER
    | CHARACTER

  rules_or_grammar_declaration:
      rules ";"*
    | grammar_declaration ";"+

  rules:
      IDENT_COLON named_ref? ":" rhs_list
        {
          result = val[3].map do |rhs|
            if rhs.reject {|sym| sym.is_a?(Grammar::Node::RuleRhs::Action) || sym.is_a?(Grammar::Node::RuleRhs::Prec) }.count > 1
              empties = rhs.select { |sym| sym.is_a?(Grammar::Node::RuleRhs::Empty) }
              empties.each do |empty|
                on_action_error("%empty on non-empty rule", empty)
              end
            end
            Grammar::Node::Rule.new(
              id: val[0],
              alias_name: val[1],
              rhs: rhs,
              location: val[0].loc
            )
           end
        }

  rhs_list:
      rhs
        {
          result = [val[0]]
        }
    | rhs_list "|" rhs
        {
          result = val[0].append(val[2])
        }

  rhs:
      /* empty */
        {
          reset_precs
          result = []
        }
    | rhs "%empty"
        {
          node = Grammar::Node::RuleRhs::Empty.new(location: val[1].loc)
          result.append(node)
        }
    | rhs symbol named_ref?
        {
          on_action_error("intermediate %prec in a rule", val[1]) if @trailing_prec_seen
          node = Grammar::Node::RuleRhs::Symbol.new(
            token: val[1], alias_name: val[2],
            location: val[1].loc
          )
          result.append(node)
        }
    | rhs symbol parameterized_suffix named_ref? TAG?
        {
          on_action_error("intermediate %prec in a rule", val[1]) if @trailing_prec_seen
          argument = Grammar::Node::RuleRhs::Symbol.new(
            token: val[1], location: val[1].loc
          )
          node = Grammar::Node::RuleRhs::InstantiateRule.new(
            name: parameterized_rule_name(val[2]), args: [argument],
            alias_name: val[3], lhs_tag: val[4],
            location: merge_locations(val[1].loc, val[4]&.loc)
          )
          result.append(node)
        }
    | rhs IDENTIFIER "(" parameterized_args ")" named_ref? TAG?
        {
          on_action_error("intermediate %prec in a rule", val[1]) if @trailing_prec_seen
          node = Grammar::Node::RuleRhs::InstantiateRule.new(
            name: val[1].s_value, args: val[3],
            alias_name: val[5], lhs_tag: val[6],
            location: merge_locations(val[1].loc, val[6]&.loc)
          )
          result.append(node)
        }
    | rhs action named_ref? TAG?
        {
          node = Grammar::Node::RuleRhs::Action.new(
            code: val[1], alias_name: val[2], tag: val[3],
            location: val[1].loc
          )
          result.append(node)
        }
    | rhs "%prec" symbol
        {
          on_action_error("multiple %prec in a rule", val[0]) if prec_seen?
          if val[0].empty?
            @opening_prec_seen = true
          else
            @trailing_prec_seen = true
          end

          node = Grammar::Node::RuleRhs::Prec.new(
            token: val[2],
            location: val[2].loc
          )
          result.append(node)
        }

  parameterized_suffix:
      "?"
    | "+"
    | "*"

  parameterized_args:
      parameterized_arg { result = [val[0]] }
    | parameterized_args ',' parameterized_arg { result = val[0].append(val[2]) }

  parameterized_arg:
      symbol
        {
          result = Grammar::Node::RuleRhs::Symbol.new(
            token: val[0], location: val[0].loc
          )
        }
    | symbol parameterized_suffix
        {
          symbol = Grammar::Node::RuleRhs::Symbol.new(
            token: val[0], location: val[0].loc
          )
          result = Grammar::Node::RuleRhs::InstantiateRule.new(
            name: parameterized_rule_name(val[1]), args: [symbol],
            location: merge_locations(val[0].loc, val[1].loc)
          )
        }
    | IDENTIFIER "(" parameterized_args ")"
        {
          result = Grammar::Node::RuleRhs::InstantiateRule.new(
            name: val[0].s_value, args: val[2],
            location: merge_locations(val[0].loc, val[3].loc)
          )
        }

  action:
      "{"
        {
          if prec_seen?
            on_action_error("multiple User_code after %prec", val[0]) if @code_after_prec
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

  epilogue_declaration:
      "%%"
        {
          begin_c_declaration('\Z')
        }
      C_DECLARATION
        {
          end_c_declaration
          result = Grammar::Node::EpilogueDecl.new(code: val[2], location: merge_locations(val[0].loc, val[2].loc))
        }

  variable: id

  value: # empty
       | IDENTIFIER
       | STRING
       | "{...}"

  string_as_id: STRING
end

---- inner

include Lrama::Tracer::Duration

def initialize(text, path, debug = false, locations = false, define = {})
  @path = path
  @grammar_file = Lrama::Lexer::GrammarFile.new(path, text)
  @yydebug = debug || define.key?('parse.trace')
  @rule_counter = Lrama::Grammar::Counter.new(0)
  @midrule_action_counter = Lrama::Grammar::Counter.new(1)
  @locations = locations
  @define = define
end

def parse
  message = "parse '#{File.basename(@path)}'"
  report_duration(message) do
    @lexer = Lrama::Lexer.new(@grammar_file)
    @grammar = Lrama::Grammar.new(@rule_counter, @midrule_action_counter, @locations, @define)
    @precedence_number = 0
    reset_precs
    nodes = do_parse
    @grammar.nodes = nodes
    @grammar.evaluate_nodes
    @grammar
  end
end

def next_token
  @lexer.next_token
end

def on_error(error_token_id, error_value, value_stack)
  case error_value
  when Lrama::Lexer::Token::Int
    location = error_value.location
    value = "#{error_value.s_value}"
  when Lrama::Lexer::Token::Token
    location = error_value.location
    value = "\"#{error_value.s_value}\""
  when Lrama::Lexer::Token::Base
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
  case error_value
  when Lrama::Lexer::Token::Base
    location = error_value.location
  when Lrama::Grammar::Node::Base
    location = error_value.location
  else
    location = @lexer.location
  end

  raise_parse_error(error_message, location)
end

private

def reset_precs
  @opening_prec_seen = false
  @trailing_prec_seen = false
  @code_after_prec = false
end

def prec_seen?
  @opening_prec_seen || @trailing_prec_seen
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

def parameterized_rule_name(suffix)
  case suffix.s_value
  when "?" then "option"
  when "+" then "nonempty_list"
  when "*" then "list"
  else raise "Unexpected parameterized suffix: #{suffix.s_value}"
  end
end

def merge_locations(*locations)
  locations = locations.compact
  first = locations.first
  last = locations.last

  Lexer::Location.new(
    grammar_file: @grammar_file,
    first_line: first.first_line,
    first_column: first.first_column,
    last_line: last.last_line,
    last_column: last.last_column
  )
end
