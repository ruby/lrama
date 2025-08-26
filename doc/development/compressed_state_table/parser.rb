# :nodoc: all
class Parser
  YYNTOKENS = 9
  YYLAST = 13
  YYTABLE_NINF = -1
  YYTABLE = [   5,   6,   7,   9,   8,   9,  11,  12,   8,   9,   1,  10,   0,   2]
  YYCHECK = [   2,   0,   3,   6,   5,   6,   8,   9,   5,   6,   4,   8,  -1,   7]

  YYPACT_NINF = -4
  YYPACT = [   6,  -4,   6,   1,  -1,   3,  -4,  -4,   6,   6,  -4,  -3,  -4]
  YYPGOTO = [  -4,  -4,  -2]

  YYDEFACT = [   2,   4,   0,   0,   0,   0,   1,   3,   0,   0,   7,   5,   6]
  YYDEFGOTO = [   0,   3,   4]

  YYR1 = [   0,   9,  10,  10,  11,  11,  11,  11]
  YYR2 = [   0,   2,   0,   2,   1,   3,   3,   3]

  YYFINAL = 6

  # Symbols
  SYM_EMPTY   = -2
  SYM_EOF     =  0 # "end of file"
  SYM_ERROR   =  1 # error
  SYM_UNDEF   =  2 # Invalid Token
  SYM_LF      =  3 # LF
  SYM_NUM     =  4 # NUM
  SYM_PLUS    =  5 # '+'
  SYM_ASTER   =  6 # '*'
  SYM_LPAREN  =  7 # '('
  SYM_RPAREN  =  8 # ')'
  # Start of nonterminal
  SYM_ACCEPT  =  9 # $accept
  SYM_PROGRAM = 10 # program
  SYM_EXPR    = 11 # expr

  def initialize(debug = false)
    @debug = debug
  end

  def parse(lexer)
    state = 0
    stack = []
    yytoken = SYM_EMPTY
    parser_action = :push_state
    next_state = nil
    rule = nil

    while true
      _parser_action = parser_action
      parser_action = nil

      case _parser_action
      when :syntax_error
        debug_print("Entering :syntax_error")

        return 1
      when :accept
        debug_print("Entering :accept")

        return 0
      when :push_state
        # Precondition: `state` is set to new state
        debug_print("Entering :push_state")

        debug_print("Push state #{state}")
        stack.push(state)
        debug_print("Current stack #{stack}")

        if state == YYFINAL
          parser_action = :accept
          next
        end

        parser_action = :decide_parser_action
        next
      when :decide_parser_action
        debug_print("Entering :decide_parser_action")

        offset = yypact[state]
        if offset == YYPACT_NINF
          parser_action = :yydefault
          next
        end

        # Ensure next token
        if yytoken == SYM_EMPTY
          debug_print("Reading a token")

          yytoken = lexer.next_token
        end

        case yytoken
        when SYM_EOF
          debug_print("Now at end of input.")
        when SYM_ERROR
          parser_action = :syntax_error
          next
        else
          debug_print("Next token is #{yytoken}")
        end

        idx = offset + yytoken
        if idx < 0 || YYLAST < idx
          debug_print("Decide next parser action as :yydefault")

          parser_action = :yydefault
          next
        end
        if yycheck[idx] != yytoken
          debug_print("Decide next parser action as :yydefault")

          parser_action = :yydefault
          next
        end

        action = yytable[idx]
        if action == YYTABLE_NINF
          parser_action = :syntax_error
          next
        end
        if action > 0
          # Shift
          debug_print("Decide next parser action as :yyshift")

          next_state = action
          parser_action = :yyshift
          next
        else
          # Reduce
          debug_print("Decide next parser action as :yyreduce")

          rule = -action
          parser_action = :yyreduce
          next
        end
      when :yyshift
        # Precondition: `next_state` is set
        debug_print("Entering :yyshift")
        raise "next_state is not set" unless next_state

        yytoken = SYM_EMPTY
        state = next_state
        next_state = nil
        parser_action = :push_state
        next
      when :yydefault
        debug_print("Entering :yydefault")

        rule = yydefact[state]
        if rule == 0
          parser_action = :syntax_error
          next
        end

        parser_action = :yyreduce
        next
      when :yyreduce
        # Precondition: `rule`, used for reduce, is set
        debug_print("Entering :yyreduce")
        raise "rule is not set" unless rule

        rhs_length = yyr2[rule]
        lhs_nterm = yyr1[rule]
        lhs_nterm_id = lhs_nterm - YYNTOKENS

        text = "Execute action for Rule (#{rule}) "
        case rule
        when 1
          text << "$accept: program \"end of file\""
        when 2
          text << "program: ε"
        when 3
          text << "program: expr LF"
        when 4
          text << "expr: NUM"
        when 5
          text << "expr: expr '+' expr"
        when 6
          text << "expr: expr '*' expr"
        when 7
          text << "expr: '(' expr ')'"
        end
        debug_print(text)

        debug_print("Pop #{rhs_length} elements")
        debug_print("Stack before pop: #{stack}")
        stack.pop(rhs_length)
        debug_print("Stack after pop: #{stack}")
        state = stack[-1]

        # "Shift" LHS nonterminal
        offset = yypgoto[lhs_nterm_id]
        if offset == YYPACT_NINF
          state = yydefgoto[lhs_nterm_id]
        else
          idx = offset + state
          if idx < 0 || YYLAST < idx
            state = yydefgoto[lhs_nterm_id]
          elsif yycheck[idx] != state
            state = yydefgoto[lhs_nterm_id]
          else
            state = yytable[idx]
          end
        end

        rule = nil
        parser_action = :push_state
        next
      else
        raise "Unknown parser_action: #{parser_action}"
      end
    end
  end

  private

  def debug_print(str)
    if @debug
      $stderr.puts str
    end
  end

  def yytable
    YYTABLE
  end

  def yycheck
    YYCHECK
  end

  def yypact
    YYPACT
  end

  def yypgoto
    YYPGOTO
  end

  def yydefact
    YYDEFACT
  end

  def yydefgoto
    YYDEFGOTO
  end

  def yyr1
    YYR1
  end

  def yyr2
    YYR2
  end
end

# :nodoc: all
class Lexer
  def initialize(tokens)
    @tokens = tokens
    @index = 0
  end

  def next_token
    if @tokens.length > @index
      token = @tokens[@index]
      @index += 1
      return token
    else
      return Parser::SYM_EOF
    end
  end
end

lexer = Lexer.new([
  # 1 + 2 + 3 LF
  Parser::SYM_NUM,
  Parser::SYM_PLUS,
  Parser::SYM_NUM,
  Parser::SYM_PLUS,
  Parser::SYM_NUM,
  Parser::SYM_LF,
])
Parser.new(debug: true).parse(lexer)
