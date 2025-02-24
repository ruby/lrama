# frozen_string_literal: true

RSpec.describe Lrama::States do
  describe '#compute' do
    it "basic" do
      path = "common/basic.y"
      y = File.read(fixture_path(path))
      grammar = Lrama::Parser.new(y, path).parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute

      io = StringIO.new
      Lrama::Reporter.new(grammar: true, rules: true, terms: true, states: true, itemsets: true, lookaheads: true).report(io, states)

      expect(io.string).to eq(<<~STR)
        1 Unused Rules

            0 unused


        11 Unused Terms

            0 YYerror
            1 YYUNDEF
            2 '\\\\'
            3 '\\13'
            4 keyword_class2
            5 tNUMBER
            6 tPLUS
            7 tMINUS
            8 tEQ
            9 tEQEQ
           10 '>'


        State 1 conflicts: 2 shift/reduce, 1 reduce/reduce


        Grammar

            0 $accept: program "EOI"

            1 program: class
            2        | '+' strings_1
            3        | '-' strings_2

            4 class: keyword_class tSTRING "end"

            5 $@1: ε

            6 $@2: ε

            7 class: keyword_class $@1 tSTRING '!' "end" $@2

            8 $@3: ε

            9 $@4: ε

           10 class: keyword_class $@3 tSTRING '?' "end" $@4

           11 strings_1: string_1

           12 strings_2: string_1
           13          | string_2

           14 string_1: string

           15 string_2: string '+'

           16 string: tSTRING

           17 unused: tNUMBER


        State 0

            0 $accept: • program "EOI"
            1 program: • class
            2        | • '+' strings_1
            3        | • '-' strings_2
            4 class: • keyword_class tSTRING "end"
            7      | • keyword_class $@1 tSTRING '!' "end" $@2
           10      | • keyword_class $@3 tSTRING '?' "end" $@4

            keyword_class  shift, and go to state 1
            '+'            shift, and go to state 2
            '-'            shift, and go to state 3

            program  go to state 4
            class    go to state 5


        State 1

            4 class: keyword_class • tSTRING "end"
            5 $@1: ε •  [tSTRING]
            7 class: keyword_class • $@1 tSTRING '!' "end" $@2
            8 $@3: ε •  [tSTRING]
           10 class: keyword_class • $@3 tSTRING '?' "end" $@4

            Conflict on tSTRING. shift/reduce($@1)
            Conflict on tSTRING. shift/reduce($@3)
            Conflict on tSTRING. reduce($@1)/reduce($@3)

            tSTRING  shift, and go to state 6

            tSTRING  reduce using rule 5 ($@1)
            tSTRING  reduce using rule 8 ($@3)

            $@1  go to state 7
            $@3  go to state 8


        State 2

            2 program: '+' • strings_1
           11 strings_1: • string_1
           14 string_1: • string
           16 string: • tSTRING

            tSTRING  shift, and go to state 9

            strings_1  go to state 10
            string_1   go to state 11
            string     go to state 12


        State 3

            3 program: '-' • strings_2
           12 strings_2: • string_1
           13          | • string_2
           14 string_1: • string
           15 string_2: • string '+'
           16 string: • tSTRING

            tSTRING  shift, and go to state 9

            strings_2  go to state 13
            string_1   go to state 14
            string_2   go to state 15
            string     go to state 16


        State 4

            0 $accept: program • "EOI"

            "EOI"  shift, and go to state 17


        State 5

            1 program: class •

            $default  reduce using rule 1 (program)


        State 6

            4 class: keyword_class tSTRING • "end"

            "end"  shift, and go to state 18


        State 7

            7 class: keyword_class $@1 • tSTRING '!' "end" $@2

            tSTRING  shift, and go to state 19


        State 8

           10 class: keyword_class $@3 • tSTRING '?' "end" $@4

            tSTRING  shift, and go to state 20


        State 9

           16 string: tSTRING •

            $default  reduce using rule 16 (string)


        State 10

            2 program: '+' strings_1 •

            $default  reduce using rule 2 (program)


        State 11

           11 strings_1: string_1 •

            $default  reduce using rule 11 (strings_1)


        State 12

           14 string_1: string •

            $default  reduce using rule 14 (string_1)


        State 13

            3 program: '-' strings_2 •

            $default  reduce using rule 3 (program)


        State 14

           12 strings_2: string_1 •

            $default  reduce using rule 12 (strings_2)


        State 15

           13 strings_2: string_2 •

            $default  reduce using rule 13 (strings_2)


        State 16

           14 string_1: string •  ["EOI"]
           15 string_2: string • '+'

            '+'  shift, and go to state 21

            $default  reduce using rule 14 (string_1)


        State 17

            0 $accept: program "EOI" •

            $default  accept


        State 18

            4 class: keyword_class tSTRING "end" •

            $default  reduce using rule 4 (class)


        State 19

            7 class: keyword_class $@1 tSTRING • '!' "end" $@2

            '!'  shift, and go to state 22


        State 20

           10 class: keyword_class $@3 tSTRING • '?' "end" $@4

            '?'  shift, and go to state 23


        State 21

           15 string_2: string '+' •

            $default  reduce using rule 15 (string_2)


        State 22

            7 class: keyword_class $@1 tSTRING '!' • "end" $@2

            "end"  shift, and go to state 24


        State 23

           10 class: keyword_class $@3 tSTRING '?' • "end" $@4

            "end"  shift, and go to state 25


        State 24

            6 $@2: ε •
            7 class: keyword_class $@1 tSTRING '!' "end" • $@2

            $default  reduce using rule 6 ($@2)

            $@2  go to state 26


        State 25

            9 $@4: ε •
           10 class: keyword_class $@3 tSTRING '?' "end" • $@4

            $default  reduce using rule 9 ($@4)

            $@4  go to state 27


        State 26

            7 class: keyword_class $@1 tSTRING '!' "end" $@2 •

            $default  reduce using rule 7 (class)


        State 27

           10 class: keyword_class $@3 tSTRING '?' "end" $@4 •

            $default  reduce using rule 10 (class)


      STR
    end

    it '#State#accessing_symbol' do
      path = "common/basic.y"
      y = File.read(fixture_path(path))
      grammar = Lrama::Parser.new(y, path).parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute

      expect(states.states.map(&:accessing_symbol)).to eq([
        states.find_symbol_by_s_value!("EOI"),
        states.find_symbol_by_s_value!("keyword_class"),
        states.find_symbol_by_s_value!("'+'"),
        states.find_symbol_by_s_value!("'-'"),
        states.find_symbol_by_s_value!("program"),
        states.find_symbol_by_s_value!("class"),
        states.find_symbol_by_s_value!("tSTRING"),
        states.find_symbol_by_s_value!("$@1"),
        states.find_symbol_by_s_value!("$@3"),
        states.find_symbol_by_s_value!("tSTRING"),
        states.find_symbol_by_s_value!("strings_1"),
        states.find_symbol_by_s_value!("string_1"),
        states.find_symbol_by_s_value!("string"),
        states.find_symbol_by_s_value!("strings_2"),
        states.find_symbol_by_s_value!("string_1"),
        states.find_symbol_by_s_value!("string_2"),
        states.find_symbol_by_s_value!("string"),
        states.find_symbol_by_s_value!("EOI"),
        states.find_symbol_by_s_value!("keyword_end"),
        states.find_symbol_by_s_value!("tSTRING"),
        states.find_symbol_by_s_value!("tSTRING"),
        states.find_symbol_by_s_value!("'+'"),
        states.find_symbol_by_s_value!("'!'"),
        states.find_symbol_by_s_value!("'?'"),
        states.find_symbol_by_s_value!("keyword_end"),
        states.find_symbol_by_s_value!("keyword_end"),
        states.find_symbol_by_s_value!("$@2"),
        states.find_symbol_by_s_value!("$@4"),
      ])
    end
  end

  describe '#reads_relation' do
    it do
      path = "states/reads_relation.y"
      y = File.read(fixture_path(path))
      grammar = Lrama::Parser.new(y, path).parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute

      io = StringIO.new
      Lrama::Reporter.new(states: true, itemsets: true, verbose: true).report(io, states)

      expect(io.string).to eq(<<~STR)
        State 0 conflicts: 1 shift/reduce
        State 7 conflicts: 1 shift/reduce


        State 0

            0 $accept: • program "end of file"
            1 program: • A
            2 A: • B C D A
            3  | • a
            4 B: ε •

            Conflict on a. shift/reduce(B)

            a  shift, and go to state 1

            a  reduce using rule 4 (B)

            program  go to state 2
            A        go to state 3
            B        go to state 4

          [Direct Read sets]
            read program  shift YYEOF

          [Reads Relation]
            (State 4, C)

          [Read sets]
            YYEOF
            a

          [Includes Relation]
            (State 0, A) -> (State 0, program)

          [Lookback Relation]
            (Rule: B -> ε) -> (State 0, B)

          [Follow sets]
            program -> YYEOF
            A -> YYEOF
            B -> a

          [Look-Ahead Sets]
            a  reduce using rule 4 (B)


        State 1

            3 A: a •

            $default  reduce using rule 3 (A)

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]

          [Lookback Relation]
            (Rule: A -> a) -> (State 0, A)
            (Rule: A -> a) -> (State 7, A)

          [Follow sets]

          [Look-Ahead Sets]
            YYEOF  reduce using rule 3 (A)


        State 2

            0 $accept: program • "end of file"

            "end of file"  shift, and go to state 5

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]

          [Lookback Relation]

          [Follow sets]

          [Look-Ahead Sets]

        State 3

            1 program: A •

            $default  reduce using rule 1 (program)

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]

          [Lookback Relation]
            (Rule: program -> A) -> (State 0, program)

          [Follow sets]

          [Look-Ahead Sets]
            YYEOF  reduce using rule 1 (program)


        State 4

            2 A: B • C D A
            5 C: ε •

            $default  reduce using rule 5 (C)

            C  go to state 6

          [Direct Read sets]

          [Reads Relation]
            (State 6, D)

          [Read sets]
            a

          [Includes Relation]

          [Lookback Relation]
            (Rule: C -> ε) -> (State 4, C)

          [Follow sets]
            C -> a

          [Look-Ahead Sets]
            a  reduce using rule 5 (C)


        State 5

            0 $accept: program "end of file" •

            $default  accept

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]

          [Lookback Relation]

          [Follow sets]

          [Look-Ahead Sets]

        State 6

            2 A: B C • D A
            6 D: ε •

            $default  reduce using rule 6 (D)

            D  go to state 7

          [Direct Read sets]
            read D  shift a

          [Reads Relation]
            (State 7, B)

          [Read sets]
            a

          [Includes Relation]

          [Lookback Relation]
            (Rule: D -> ε) -> (State 6, D)

          [Follow sets]
            D -> a

          [Look-Ahead Sets]
            a  reduce using rule 6 (D)


        State 7

            2 A: • B C D A
            2  | B C D • A
            3  | • a
            4 B: ε •

            Conflict on a. shift/reduce(B)

            a  shift, and go to state 1

            a  reduce using rule 4 (B)

            A  go to state 8
            B  go to state 4

          [Direct Read sets]

          [Reads Relation]
            (State 4, C)

          [Read sets]
            a

          [Includes Relation]
            (State 7, A) -> (State 0, A)
            (State 7, A) -> (State 7, A)

          [Lookback Relation]
            (Rule: B -> ε) -> (State 7, B)

          [Follow sets]
            A -> YYEOF
            B -> a

          [Look-Ahead Sets]
            a  reduce using rule 4 (B)


        State 8

            2 A: B C D A •

            $default  reduce using rule 2 (A)

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]

          [Lookback Relation]
            (Rule: A -> B C D A) -> (State 0, A)
            (Rule: A -> B C D A) -> (State 7, A)

          [Follow sets]

          [Look-Ahead Sets]
            YYEOF  reduce using rule 2 (A)


      STR
    end
  end

  describe '#includes_relation' do
    it do
      path = "states/includes_relation.y"
      y = File.read(fixture_path(path))
      grammar = Lrama::Parser.new(y, path).parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute

      io = StringIO.new
      Lrama::Reporter.new(states: true, itemsets: true, verbose: true).report(io, states)

      expect(io.string).to eq(<<~STR)
        State 0

            0 $accept: • program "end of file"
            1 program: • A
            2 A: • b B
            3  | • a

            a  shift, and go to state 1
            b  shift, and go to state 2

            program  go to state 3
            A        go to state 4

          [Direct Read sets]
            read program  shift YYEOF

          [Reads Relation]

          [Read sets]
            YYEOF

          [Includes Relation]
            (State 0, A) -> (State 0, program)

          [Lookback Relation]

          [Follow sets]
            program -> YYEOF
            A -> YYEOF

          [Look-Ahead Sets]

        State 1

            3 A: a •

            $default  reduce using rule 3 (A)

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]

          [Lookback Relation]
            (Rule: A -> a) -> (State 0, A)
            (Rule: A -> a) -> (State 8, A)

          [Follow sets]

          [Look-Ahead Sets]
            YYEOF  reduce using rule 3 (A)


        State 2

            2 A: b • B
            4 B: • c C

            c  shift, and go to state 5

            B  go to state 6

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]
            (State 2, B) -> (State 0, A)
            (State 2, B) -> (State 8, A)

          [Lookback Relation]

          [Follow sets]
            B -> YYEOF

          [Look-Ahead Sets]

        State 3

            0 $accept: program • "end of file"

            "end of file"  shift, and go to state 7

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]

          [Lookback Relation]

          [Follow sets]

          [Look-Ahead Sets]

        State 4

            1 program: A •

            $default  reduce using rule 1 (program)

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]

          [Lookback Relation]
            (Rule: program -> A) -> (State 0, program)

          [Follow sets]

          [Look-Ahead Sets]
            YYEOF  reduce using rule 1 (program)


        State 5

            4 B: c • C
            5 C: • d A

            d  shift, and go to state 8

            C  go to state 9

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]
            (State 5, C) -> (State 2, B)

          [Lookback Relation]

          [Follow sets]
            C -> YYEOF

          [Look-Ahead Sets]

        State 6

            2 A: b B •

            $default  reduce using rule 2 (A)

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]

          [Lookback Relation]
            (Rule: A -> b B) -> (State 0, A)
            (Rule: A -> b B) -> (State 8, A)

          [Follow sets]

          [Look-Ahead Sets]
            YYEOF  reduce using rule 2 (A)


        State 7

            0 $accept: program "end of file" •

            $default  accept

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]

          [Lookback Relation]

          [Follow sets]

          [Look-Ahead Sets]

        State 8

            2 A: • b B
            3  | • a
            5 C: d • A

            a  shift, and go to state 1
            b  shift, and go to state 2

            A  go to state 10

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]
            (State 8, A) -> (State 5, C)

          [Lookback Relation]

          [Follow sets]
            A -> YYEOF

          [Look-Ahead Sets]

        State 9

            4 B: c C •

            $default  reduce using rule 4 (B)

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]

          [Lookback Relation]
            (Rule: B -> c C) -> (State 2, B)

          [Follow sets]

          [Look-Ahead Sets]
            YYEOF  reduce using rule 4 (B)


        State 10

            5 C: d A •

            $default  reduce using rule 5 (C)

          [Direct Read sets]

          [Reads Relation]

          [Read sets]

          [Includes Relation]

          [Lookback Relation]
            (Rule: C -> d A) -> (State 5, C)

          [Follow sets]

          [Look-Ahead Sets]
            YYEOF  reduce using rule 5 (C)


      STR
    end
  end

  describe '#compute_look_ahead_sets' do
    describe "state has 1 reduces and no transitions" do
      it "does not set look_ahead_sets" do
        y = <<~INPUT
          %{
          // Prologue
          %}

          %token EOI 0 "EOI"
          %token tNUMBER

          %%

          program: expr ;

          expr: tNUMBER
              ;

          %%
        INPUT
        grammar = Lrama::Parser.new(y, "states/compute_look_ahead_sets.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute

        io = StringIO.new
        Lrama::Reporter.new(states: true, lookaheads: true).report(io, states)

        expect(io.string).to eq(<<~STR)
          State 0

              0 $accept: • program "EOI"

              tNUMBER  shift, and go to state 1

              program  go to state 2
              expr     go to state 3


          State 1

              2 expr: tNUMBER •

              $default  reduce using rule 2 (expr)


          State 2

              0 $accept: program • "EOI"

              "EOI"  shift, and go to state 4


          State 3

              1 program: expr •

              $default  reduce using rule 1 (program)


          State 4

              0 $accept: program "EOI" •

              $default  accept


        STR
      end
    end

    describe "state has 1 reduces and no term transitions" do
      it "does not set look_ahead_sets" do
        y = <<~INPUT
          %{
          // Prologue
          %}

          %token EOI 0 "EOI"
          %token tNUMBER

          %%

          program: {} expr ;

          expr: tNUMBER
              ;

          %%
        INPUT
        grammar = Lrama::Parser.new(y, "states/compute_look_ahead_sets.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute

        io = StringIO.new
        Lrama::Reporter.new(states: true, lookaheads: true, itemsets: true).report(io, states)

        expect(io.string).to eq(<<~STR)
          State 0

              0 $accept: • program "EOI"
              1 $@1: ε •
              2 program: • $@1 expr

              $default  reduce using rule 1 ($@1)

              $@1      go to state 1
              program  go to state 2


          State 1

              2 program: $@1 • expr
              3 expr: • tNUMBER

              tNUMBER  shift, and go to state 3

              expr  go to state 4


          State 2

              0 $accept: program • "EOI"

              "EOI"  shift, and go to state 5


          State 3

              3 expr: tNUMBER •

              $default  reduce using rule 3 (expr)


          State 4

              2 program: $@1 expr •

              $default  reduce using rule 2 (program)


          State 5

              0 $accept: program "EOI" •

              $default  accept


        STR
      end
    end
  end

  describe '#compute_conflicts' do
    describe "rules have no explicit precedence" do
      it "inherits precedence from the last term in RHS" do
        y = <<~INPUT
          %{
          // Prologue
          %}

          %token EOI 0 "EOI"
          %token tNUMBER
          %token tUPLUS "unary+"
          %token tPLUS  "+"

          %left  tPLUS
          %right tUPLUS

          %%

          program: expr ;

          expr: tUPLUS expr
              | expr tPLUS expr
              | tNUMBER
              ;

          %%
        INPUT
        grammar = Lrama::Parser.new(y, "states/compute_conflicts.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute

        io = StringIO.new
        Lrama::Reporter.new(states: true, solved: true).report(io, states)

        expect(io.string).to eq(<<~STR)
          State 0

              0 $accept: • program "EOI"

              tNUMBER   shift, and go to state 1
              "unary+"  shift, and go to state 2

              program  go to state 3
              expr     go to state 4


          State 1

              4 expr: tNUMBER •

              $default  reduce using rule 4 (expr)


          State 2

              2 expr: "unary+" • expr

              tNUMBER   shift, and go to state 1
              "unary+"  shift, and go to state 2

              expr  go to state 5


          State 3

              0 $accept: program • "EOI"

              "EOI"  shift, and go to state 6


          State 4

              1 program: expr •
              3 expr: expr • "+" expr

              "+"  shift, and go to state 7

              $default  reduce using rule 1 (program)


          State 5

              2 expr: "unary+" expr •
              3     | expr • "+" expr

              $default  reduce using rule 2 (expr)

              Conflict between rule 2 and token "+" resolved as reduce ("+" < "unary+").


          State 6

              0 $accept: program "EOI" •

              $default  accept


          State 7

              3 expr: expr "+" • expr

              tNUMBER   shift, and go to state 1
              "unary+"  shift, and go to state 2

              expr  go to state 8


          State 8

              3 expr: expr • "+" expr
              3     | expr "+" expr •

              $default  reduce using rule 3 (expr)

              Conflict between rule 3 and token "+" resolved as reduce (%left "+").


        STR
      end
    end

    describe "conflict happens on %nonassoc operator" do
      it "resolved as 'run-time' error" do
        y = <<~INPUT
          %{
          // Prologue
          %}

          %token EOI 0 "EOI"
          %token tNUMBER
          %token tEQ "="

          %nonassoc tEQ

          %%

          program: expr ;

          expr: expr tEQ expr
              | tNUMBER
              ;

          %%
        INPUT
        grammar = Lrama::Parser.new(y, "states/compute_conflicts.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute

        io = StringIO.new
        Lrama::Reporter.new(states: true, solved: true).report(io, states)

        expect(io.string).to eq(<<~STR)
          State 0

              0 $accept: • program "EOI"

              tNUMBER  shift, and go to state 1

              program  go to state 2
              expr     go to state 3


          State 1

              3 expr: tNUMBER •

              $default  reduce using rule 3 (expr)


          State 2

              0 $accept: program • "EOI"

              "EOI"  shift, and go to state 4


          State 3

              1 program: expr •
              2 expr: expr • "=" expr

              "="  shift, and go to state 5

              $default  reduce using rule 1 (program)


          State 4

              0 $accept: program "EOI" •

              $default  accept


          State 5

              2 expr: expr "=" • expr

              tNUMBER  shift, and go to state 1

              expr  go to state 6


          State 6

              2 expr: expr • "=" expr
              2     | expr "=" expr •

              "="  error (nonassociative)

              $default  reduce using rule 2 (expr)

              Conflict between rule 2 and token "=" resolved as an error (%nonassoc "=").


        STR
      end
    end

    describe "conflict happens on %precedence operator" do
      it "resolved as 'run-time' error so that conflict is kept" do
        y = <<~INPUT
          %{
          // Prologue
          %}

          %token NUM

          %precedence '+'
          %precedence '*'

          %%

          program: expr ;

          expr: expr '+' expr
              | expr '*' expr
              | NUM
              ;

          %%
        INPUT
        grammar = Lrama::Parser.new(y, "states/compute_conflicts.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute

        io = StringIO.new
        Lrama::Reporter.new(states: true, solved: true).report(io, states)

        expect(io.string).to eq(<<~STR)
          State 7 conflicts: 1 shift/reduce
          State 8 conflicts: 1 shift/reduce


          State 0

              0 $accept: • program "end of file"

              NUM  shift, and go to state 1

              program  go to state 2
              expr     go to state 3


          State 1

              4 expr: NUM •

              $default  reduce using rule 4 (expr)


          State 2

              0 $accept: program • "end of file"

              "end of file"  shift, and go to state 4


          State 3

              1 program: expr •
              2 expr: expr • '+' expr
              3     | expr • '*' expr

              '+'  shift, and go to state 5
              '*'  shift, and go to state 6

              $default  reduce using rule 1 (program)


          State 4

              0 $accept: program "end of file" •

              $default  accept


          State 5

              2 expr: expr '+' • expr

              NUM  shift, and go to state 1

              expr  go to state 7


          State 6

              3 expr: expr '*' • expr

              NUM  shift, and go to state 1

              expr  go to state 8


          State 7

              2 expr: expr • '+' expr
              2     | expr '+' expr •
              3     | expr • '*' expr

              Conflict on '+'. shift/reduce(expr)

              '+'  shift, and go to state 5
              '*'  shift, and go to state 6

              "end of file"  reduce using rule 2 (expr)
              '+'            reduce using rule 2 (expr)
              '*'            reduce using rule 2 (expr)

              Conflict between rule 2 and token '*' resolved as shift ('+' < '*').


          State 8

              2 expr: expr • '+' expr
              3     | expr • '*' expr
              3     | expr '*' expr •

              Conflict on '*'. shift/reduce(expr)

              '*'  shift, and go to state 6

              "end of file"  reduce using rule 3 (expr)
              '+'            reduce using rule 3 (expr)
              '*'            reduce using rule 3 (expr)

              Conflict between rule 3 and token '+' resolved as reduce ('+' < '*').


        STR
      end
    end
  end

  describe '#compute_default_reduction' do
    it "selects a rule having most lookahead as default reduction rule" do
      y = <<~INPUT
        %{
        // Prologue
        %}

        %union {
            int i;
        }

        %token EOI 0 "EOI"
        %token <l> tNUMBER
        %token <str> tID
        %token tPLUS  "+"
        %token tMINUS "-"
        %token do
        %token end
        %token tCOLON2 "::"

        %%

        program: stmt ;

        stmt: expr
            ;

        expr: primary do end
            | receiver '.' ident
            | receiver tCOLON2 ident
            ;

        receiver: ident ;

        primary: ident ;

        ident: tID ;

        %%
      INPUT
      grammar = Lrama::Parser.new(y, "states/compute_default_reduction.y").parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute

      io = StringIO.new
      Lrama::Reporter.new(states: true).report(io, states)

      expect(io.string).to eq(<<~STR)
        State 0

            0 $accept: • program "EOI"

            tID  shift, and go to state 1

            program   go to state 2
            stmt      go to state 3
            expr      go to state 4
            receiver  go to state 5
            primary   go to state 6
            ident     go to state 7


        State 1

            8 ident: tID •

            $default  reduce using rule 8 (ident)


        State 2

            0 $accept: program • "EOI"

            "EOI"  shift, and go to state 8


        State 3

            1 program: stmt •

            $default  reduce using rule 1 (program)


        State 4

            2 stmt: expr •

            $default  reduce using rule 2 (stmt)


        State 5

            4 expr: receiver • '.' ident
            5     | receiver • "::" ident

            "::"  shift, and go to state 9
            '.'   shift, and go to state 10


        State 6

            3 expr: primary • do end

            do  shift, and go to state 11


        State 7

            6 receiver: ident •
            7 primary: ident •

            do        reduce using rule 7 (primary)
            $default  reduce using rule 6 (receiver)


        State 8

            0 $accept: program "EOI" •

            $default  accept


        State 9

            5 expr: receiver "::" • ident

            tID  shift, and go to state 1

            ident  go to state 12


        State 10

            4 expr: receiver '.' • ident

            tID  shift, and go to state 1

            ident  go to state 13


        State 11

            3 expr: primary do • end

            end  shift, and go to state 14


        State 12

            5 expr: receiver "::" ident •

            $default  reduce using rule 5 (expr)


        State 13

            4 expr: receiver '.' ident •

            $default  reduce using rule 4 (expr)


        State 14

            3 expr: primary do end •

            $default  reduce using rule 3 (expr)


      STR
    end

    it "does not have default_reduction_rule if error token can be shifted" do
      y = <<~INPUT
        %{
        // Prologue
        %}

        %union {
            int i;
        }

        %token EOI 0 "EOI"
        %token <l> tNUMBER
        %token <str> tID
        %token tPLUS  "+"
        %token tMINUS "-"
        %token do
        %token end
        %token tCOLON2 "::"

        %%

        program: stmt ;

        stmt: expr
            ;

        expr: primary do end
            | receiver '.' ident
            | receiver tCOLON2 ident
            ;

        receiver: ident
                | ident error
                ;

        primary: ident ;

        ident: tID ;

        %%
      INPUT
      grammar = Lrama::Parser.new(y, "states/compute_default_reduction.y").parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute

      io = StringIO.new
      Lrama::Reporter.new(states: true).report(io, states)

      expect(io.string).to eq(<<~STR)
        State 0

            0 $accept: • program "EOI"

            tID  shift, and go to state 1

            program   go to state 2
            stmt      go to state 3
            expr      go to state 4
            receiver  go to state 5
            primary   go to state 6
            ident     go to state 7


        State 1

            9 ident: tID •

            $default  reduce using rule 9 (ident)


        State 2

            0 $accept: program • "EOI"

            "EOI"  shift, and go to state 8


        State 3

            1 program: stmt •

            $default  reduce using rule 1 (program)


        State 4

            2 stmt: expr •

            $default  reduce using rule 2 (stmt)


        State 5

            4 expr: receiver • '.' ident
            5     | receiver • "::" ident

            "::"  shift, and go to state 9
            '.'   shift, and go to state 10


        State 6

            3 expr: primary • do end

            do  shift, and go to state 11


        State 7

            6 receiver: ident •
            7         | ident • error
            8 primary: ident •

            error  shift, and go to state 12

            do    reduce using rule 8 (primary)
            "::"  reduce using rule 6 (receiver)
            '.'   reduce using rule 6 (receiver)


        State 8

            0 $accept: program "EOI" •

            $default  accept


        State 9

            5 expr: receiver "::" • ident

            tID  shift, and go to state 1

            ident  go to state 13


        State 10

            4 expr: receiver '.' • ident

            tID  shift, and go to state 1

            ident  go to state 14


        State 11

            3 expr: primary do • end

            end  shift, and go to state 15


        State 12

            7 receiver: ident error •

            $default  reduce using rule 7 (receiver)


        State 13

            5 expr: receiver "::" ident •

            $default  reduce using rule 5 (expr)


        State 14

            4 expr: receiver '.' ident •

            $default  reduce using rule 4 (expr)


        State 15

            3 expr: primary do end •

            $default  reduce using rule 3 (expr)


      STR
    end
  end

  describe '#compute_ielr' do
    it 'recompute states' do
      path = "integration/ielr.y"
      y = File.read(fixture_path(path))
      grammar = Lrama::Parser.new(y, path).parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      states.compute_ielr

      io = StringIO.new
      Lrama::Reporter.new(states: true).report(io, states)

      expect(io.string).to eq(<<~STR)
        State 0

            0 $accept: • S "end of file"

            a  shift, and go to state 1
            b  shift, and go to state 2

            S  go to state 3

            inadequacy annotation manifesting state 14, token a
              state 0 always contributes to shift by a
              state 0 always contributes to reduce by 'E: '


        State 1

            1 S: a • A B a

            a  shift, and go to state 4

            A  go to state 5

            inadequacy annotation manifesting state 14, token a
              state 1 always contributes to shift by a
              state 1 always contributes to reduce by 'E: '


        State 2

            2 S: b • A B b

            a  shift, and go to state 19

            A  go to state 6

            inadequacy annotation manifesting state 14, token a
              state 2 always contributes to shift by a
              'b • A B b' never contributes to reduce by 'E: '


        State 3

            0 $accept: S • "end of file"

            "end of file"  shift, and go to state 7


        State 4

            3 A: a • C D E

            a  shift, and go to state 8

            C  go to state 9
            D  go to state 10

            inadequacy annotation manifesting state 14, token a
              state 4 always contributes to shift by a
              'a • C D E' potentially contributes to reduce by 'E: '


        State 5

            1 S: a A • B a

            c  shift, and go to state 11

            $default  reduce using rule 5 (B)

            B  go to state 12


        State 6

            2 S: b A • B b

            c  shift, and go to state 11

            $default  reduce using rule 5 (B)

            B  go to state 13


        State 7

            0 $accept: S "end of file" •

            $default  accept


        State 8

            7 D: a •

            $default  reduce using rule 7 (D)


        State 9

            3 A: a C • D E

            a  shift, and go to state 8

            D  go to state 14

            inadequacy annotation manifesting state 14, token a
              state 9 always contributes to shift by a
              'a C • D E' potentially contributes to reduce by 'E: '


        State 10

            6 C: D •

            $default  reduce using rule 6 (C)


        State 11

            4 B: c •

            $default  reduce using rule 4 (B)


        State 12

            1 S: a A B • a

            a  shift, and go to state 15


        State 13

            2 S: b A B • b

            b  shift, and go to state 16


        State 14

            3 A: a C D • E

            $default  reduce using rule 9 (E)

            E  go to state 18

            inadequacy annotation manifesting state 14, token a
              state 14 always contributes to shift by a
              'a C D • E' potentially contributes to reduce by 'E: '


        State 15

            1 S: a A B a •

            $default  reduce using rule 1 (S)


        State 16

            2 S: b A B b •

            $default  reduce using rule 2 (S)


        State 17

            8 E: a •

            $default  reduce using rule 8 (E)


        State 18

            3 A: a C D E •

            $default  reduce using rule 3 (A)


        State 19

            3 A: a • C D E

            a  shift, and go to state 8

            C  go to state 20
            D  go to state 10


        State 20

            3 A: a C • D E

            a  shift, and go to state 8

            D  go to state 21


        State 21

            3 A: a C D • E

            a  shift, and go to state 17

            $default  reduce using rule 9 (E)

            E  go to state 18


      STR
    end

    xit 'recompute states' do
      pending "TODO: Clarify expected result and fix this test"
      y = <<~INPUT
        %{
        // Prologue
        %}

        %token <val> NUM
        %token tEQ "=="
        %type <val> expr

        %nonassoc tEQ

        %%

        program : /* empty */
             | expr { printf("=> %d", $1); }
             ;

        expr : NUM
             | expr tEQ expr { $$ = $1; }
             ;

        %%
      INPUT
      grammar = Lrama::Parser.new(y, "states/ielr_nonassoc.y").parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      states.compute_ielr

      io = StringIO.new
      Lrama::Reporter.new(states: true).report(io, states)

      expect(io.string).to eq(<<~STR)
        State 0

            0 $accept: • program "end of file"

            NUM  shift, and go to state 1

            $default  reduce using rule 1 (program)

            program  go to state 2
            expr     go to state 3


        State 1

            3 expr: NUM •

            $default  reduce using rule 3 (expr)


        State 2

            0 $accept: program • "end of file"

            "end of file"  shift, and go to state 4


        State 3

            2 program: expr •
            4 expr: expr • "==" expr

            "=="  shift, and go to state 5

            $default  reduce using rule 2 (program)


        State 4

            0 $accept: program "end of file" •

            $default  accept


        State 5

            4 expr: expr "==" • expr

            NUM  shift, and go to state 1

            expr  go to state 6


        State 6

            4 expr: expr • "==" expr
            4     | expr "==" expr •

            "=="  error (nonassociative)
            "=="  error (nonassociative)

            $default  reduce using rule 4 (expr)


        State 7

            4 expr: expr "==" • expr

            NUM  shift, and go to state 1

            expr  go to state 8


        State 8

            4 expr: expr • "==" expr
            4     | expr "==" expr •

            "=="  error (nonassociative)

            $default  reduce using rule 4 (expr)


      STR
    end

    xit 'recompute states' do
      pending "TODO: Clarify expected result and fix this test"
      y = <<~INPUT
        %{
        // Prologue
        %}

        %token NUM

        %nonassoc  tCMP
        %left '>'
        %left '+'

        %%

        program : arg
                ;

        arg : arg '+' arg
            | rel_expr    %prec tCMP
            | NUM
            ;

        relop : '>'
              ;

        rel_expr : arg relop arg   %prec '>'
                 ;

        %%
      INPUT
      grammar = Lrama::Parser.new(y, "states/ielr_prec.y").parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      states.compute_ielr

      io = StringIO.new
      Lrama::Reporter.new(states: true).report(io, states)

      expect(io.string).to eq(<<~STR)
        State 0

            0 $accept: • program "end of file"

            NUM  shift, and go to state 1

            program   go to state 2
            arg       go to state 3
            rel_expr  go to state 4


        State 1

            4 arg: NUM •

            $default  reduce using rule 4 (arg)


        State 2

            0 $accept: program • "end of file"

            "end of file"  shift, and go to state 5


        State 3

            1 program: arg •
            2 arg: arg • '+' arg
            6 rel_expr: arg • relop arg

            '>'  shift, and go to state 6
            '+'  shift, and go to state 7

            $default  reduce using rule 1 (program)

            relop  go to state 8


        State 4

            3 arg: rel_expr •

            $default  reduce using rule 3 (arg)


        State 5

            0 $accept: program "end of file" •

            $default  accept


        State 6

            5 relop: '>' •

            $default  reduce using rule 5 (relop)


        State 7

            2 arg: arg '+' • arg

            NUM  shift, and go to state 1

            arg       go to state 9
            rel_expr  go to state 4


        State 8

            6 rel_expr: arg relop • arg

            NUM  shift, and go to state 1

            arg       go to state 10
            rel_expr  go to state 4


        State 9

            2 arg: arg • '+' arg
            2    | arg '+' arg •
            6 rel_expr: arg • relop arg

            $default  reduce using rule 2 (arg)

            relop  go to state 8


        State 10

            2 arg: arg • '+' arg
            6 rel_expr: arg • relop arg
            6         | arg relop arg •

            '+'  shift, and go to state 7

            $default  reduce using rule 6 (rel_expr)

            relop  go to state 12


        State 11

            2 arg: arg '+' • arg

            NUM  shift, and go to state 1

            arg       go to state 13
            rel_expr  go to state 4


        State 12

            6 rel_expr: arg relop • arg

            NUM  shift, and go to state 1

            arg       go to state 14
            rel_expr  go to state 4


        State 13

            2 arg: arg • '+' arg
            2    | arg '+' arg •
            6 rel_expr: arg • relop arg

            $default  reduce using rule 2 (arg)

            relop  go to state 8


        State 14

            2 arg: arg • '+' arg
            6 rel_expr: arg • relop arg
            6         | arg relop arg •

            '+'  shift, and go to state 7

            $default  reduce using rule 6 (rel_expr)

            relop  go to state 12


      STR
    end

    it 'recompute states' do
      y = <<~INPUT
        %{
        // Prologue
        %}

        %token a
        %token b
        %token c

        %precedence tLOWEST
        %precedence a
        %precedence tHIGHEST

        %%

        S: S2
         ;

        S2: a A B a
          | b A B b
          ;

        A: a C D E
         ;

        B: c
         | // empty
         ;

        C: D
         ;

        D: a
         ;

        E: a
         | %prec tHIGHEST // empty
         ;

        %%
      INPUT
      grammar = Lrama::Parser.new(y, "states/ArgumentError_on_goto_follows.y").parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      expect { states.compute_ielr }.not_to raise_error

      io = StringIO.new
      Lrama::Reporter.new(states: true).report(io, states)

      expect(io.string).to eq(<<~STR)
        State 0

            0 $accept: • S "end of file"

            a  shift, and go to state 1
            b  shift, and go to state 2

            S   go to state 3
            S2  go to state 4


        State 1

            2 S2: a • A B a

            a  shift, and go to state 5

            A  go to state 6


        State 2

            3 S2: b • A B b

            a  shift, and go to state 20

            A  go to state 7


        State 3

            0 $accept: S • "end of file"

            "end of file"  shift, and go to state 8


        State 4

            1 S: S2 •

            $default  reduce using rule 1 (S)


        State 5

            4 A: a • C D E

            a  shift, and go to state 9

            C  go to state 10
            D  go to state 11


        State 6

            2 S2: a A • B a

            c  shift, and go to state 12

            $default  reduce using rule 6 (B)

            B  go to state 13


        State 7

            3 S2: b A • B b

            c  shift, and go to state 12

            $default  reduce using rule 6 (B)

            B  go to state 14


        State 8

            0 $accept: S "end of file" •

            $default  accept


        State 9

            8 D: a •

            $default  reduce using rule 8 (D)


        State 10

            4 A: a C • D E

            a  shift, and go to state 9

            D  go to state 15


        State 11

            7 C: D •

            $default  reduce using rule 7 (C)


        State 12

            5 B: c •

            $default  reduce using rule 5 (B)


        State 13

            2 S2: a A B • a

            a  shift, and go to state 16


        State 14

            3 S2: b A B • b

            b  shift, and go to state 17


        State 15

            4 A: a C D • E

            $default  reduce using rule 10 (E)

            E  go to state 19


        State 16

            2 S2: a A B a •

            $default  reduce using rule 2 (S2)


        State 17

            3 S2: b A B b •

            $default  reduce using rule 3 (S2)


        State 18

            9 E: a •

            $default  reduce using rule 9 (E)


        State 19

            4 A: a C D E •

            $default  reduce using rule 4 (A)


        State 20

            4 A: a • C D E

            a  shift, and go to state 9

            C  go to state 21
            D  go to state 11


        State 21

            4 A: a C • D E

            a  shift, and go to state 9

            D  go to state 22


        State 22

            4 A: a C D • E

            a  shift, and go to state 18

            $default  reduce using rule 10 (E)

            E  go to state 19


      STR
    end
  end

  describe "#validate!" do
    let(:y) do
      <<~STR
        %union {
            int i;
            long l;
            char *str;
        }

        %token EOI 0 "EOI"
        %token <i> '\\'  "backslash"
        %token <i> '\13' "escaped vertical tab"
        %token <i> keyword_class
        %token <i> keyword_class2
        %token <l> tNUMBER
        %token <str> tSTRING
        %token <i> keyword_end "end"
        %token tPLUS  "+"
        %token tMINUS "-"
        %token tEQ    "="
        %token tEQEQ  "=="

        %type <i> class /* comment for class */

        %nonassoc tEQEQ
        %left  tPLUS tMINUS '>'
        %right tEQ

        %%

        program: class
               | '+' strings_1
               | '-' strings_2
               ;

        class : keyword_class tSTRING keyword_end %prec tPLUS
                  { code 1 }
              | keyword_class { code 2 } tSTRING '!' keyword_end { code 3 } %prec "="
              | keyword_class { code 4 } tSTRING '?' keyword_end { code 5 } %prec '>'
              ;

        strings_1: string_1
                 ;

        strings_2: string_1
                 | string_2
                 ;

        string_1: string
                ;

          string_2: string '+'
                  ;

          string: tSTRING
                ;

          %%
      STR
    end

    context "when %expect is specified" do
      context "when the number of s/r conflicts is same with expect" do
        let(:header) do
          <<~STR
            %{
            // Prologue
            %}

            %expect 2
          STR
        end

        it "has errors for r/r conflicts" do
          grammar = Lrama::Parser.new(header + y, "states/check_conflicts.y").parse
          grammar.prepare
          grammar.validate!
          states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
          states.compute
          logger = Lrama::Logger.new
          allow(logger).to receive(:error)

          expect{ states.validate!(logger) }.to raise_error(SystemExit)
          expect(logger).to have_received(:error).with("reduce/reduce conflicts: 1 found, 0 expected")
        end
      end

      context "when the number of s/r conflicts is not same with expect" do
        let(:header) do
          <<~STR
            %{
            // Prologue
            %}

            %expect 0
          STR
        end

        it "has errors for s/r conflicts and r/r conflicts" do
          grammar = Lrama::Parser.new(header + y, "states/check_conflicts.y").parse
          grammar.prepare
          grammar.validate!
          states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
          states.compute
          logger = Lrama::Logger.new
          allow(logger).to receive(:error)

          expect{ states.validate!(logger) }.to raise_error(SystemExit)
          expect(logger).to have_received(:error).with("shift/reduce conflicts: 2 found, 0 expected")
          expect(logger).to have_received(:error).with("reduce/reduce conflicts: 1 found, 0 expected")
        end
      end
    end

    describe "%expect is not specified" do
      let(:header) do
        <<~STR
          %{
          // Prologue
          %}
        STR
      end

      it "has warns for s/r conflicts and r/r conflicts" do
        grammar = Lrama::Parser.new(header + y, "states/check_conflicts.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = Lrama::Logger.new
        allow(logger).to receive(:error)

        states.validate!(logger)
        expect(logger).not_to have_received(:error)
      end
    end
  end
end
