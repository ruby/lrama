# frozen_string_literal: true

RSpec.describe Lrama::Reporter::States do
  describe "#report_conflicts" do
    it "reports conflcts on states" do
      y = <<~INPUT
        %{
        // Prologue
        %}

        %token '+' "plus"
        %token tNUMBER

        %%

        program: expr
               ;

        expr: expr '+' expr
            | tNUMBER
            ;

        %%
      INPUT

      grammar = Lrama::Parser.new(y, "conflcts.y").parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute

      io = StringIO.new
      Lrama::Reporter.new(grammar: true, rules: true, terms: true, states: true, itemsets: true, lookaheads: true).report(io, states)

      expect(io.string).to eq(<<~STR)
        Rule Usage Frequency

            0 expr (3 times)
            1 '+' (1 times)
            2 YYEOF (1 times)
            3 program (1 times)
            4 tNUMBER (1 times)


        5 Terms

        3 Non-Terminals

        2 Unused Terms

            0 YYerror
            1 YYUNDEF


        State 6 conflicts: 1 shift/reduce


        Grammar

            0 $accept: program "end of file"

            1 program: expr

            2 expr: expr "plus" expr
            3     | tNUMBER


        State 0

            0 $accept: • program "end of file"
            1 program: • expr
            2 expr: • expr "plus" expr
            3     | • tNUMBER

            tNUMBER  shift, and go to state 1

            program  go to state 2
            expr     go to state 3


        State 1

            3 expr: tNUMBER •

            $default  reduce using rule 3 (expr)


        State 2

            0 $accept: program • "end of file"

            "end of file"  shift, and go to state 4


        State 3

            1 program: expr •  ["end of file"]
            2 expr: expr • "plus" expr

            "plus"  shift, and go to state 5

            $default  reduce using rule 1 (program)


        State 4

            0 $accept: program "end of file" •

            $default  accept


        State 5

            2 expr: • expr "plus" expr
            2     | expr "plus" • expr
            3     | • tNUMBER

            tNUMBER  shift, and go to state 1

            expr  go to state 6


        State 6

            2 expr: expr • "plus" expr
            2     | expr "plus" expr •  ["end of file", "plus"]

            Conflict on "plus". shift/reduce(expr)

            "plus"  shift, and go to state 5

            "end of file"  reduce using rule 2 (expr)
            "plus"         reduce using rule 2 (expr)


      STR
    end
  end
end
