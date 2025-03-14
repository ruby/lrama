# frozen_string_literal: true

RSpec.describe Lrama::Counterexamples do
  describe "#compute" do
    # Example comes from https://www.cs.cornell.edu/andru/papers/cupex/cupex.pdf
    # "4. Constructing Nonunifying Counterexamples"
    describe "Example of 'Finding Counterexamples from Parsing Conflicts'" do
      let(:y) do
        <<~STR
          %{
          // Prologue
          %}

          %union {
              int i;
          }

          %token <i> keyword_if
          %token <i> keyword_then
          %token <i> keyword_else
          %token <i> arr
          %token tEQ ":="
          %token <i> digit

          %type <i> stmt
          %type <i> expr
          %type <i> num

          %%

          stmt : keyword_if expr keyword_then stmt keyword_else stmt
               | keyword_if expr keyword_then stmt
               | expr '?' stmt stmt
               | arr '[' expr ']' tEQ expr
               ;

          expr : num
               | expr '+' expr
               ;

          num  : digit
               | num digit
               ;


          %%

        STR
      end

      it "build counterexamples of S/R conflicts" do
        grammar = Lrama::Parser.new(y, "parse.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        counterexamples = Lrama::Counterexamples.new(states)

        # State 6
        #
        #     5 expr: num •  ["end of file", keyword_if, keyword_then, keyword_else, arr, digit, '?', ']', '+']
        #     8 num: num • digit
        #
        #     digit  shift, and go to state 12
        #     digit         reduce using rule 5 (expr)
        state_6 = states.states[6]
        examples = counterexamples.compute(state_6)
        expect(examples.count).to eq 1
        example = examples[0]

        expect(example.type).to eq :shift_reduce
        # Shift Conflict
        expect(example.path1.map(&:state_item).map(&:item).map(&:to_s)).to eq([
          "$accept: • stmt \"end of file\"  (rule 0)",
          "stmt: • expr '?' stmt stmt  (rule 3)",
          "stmt: expr • '?' stmt stmt  (rule 3)",
          "stmt: expr '?' • stmt stmt  (rule 3)",
          "stmt: • arr '[' expr ']' \":=\" expr  (rule 4)",
          "stmt: arr • '[' expr ']' \":=\" expr  (rule 4)",
          "stmt: arr '[' • expr ']' \":=\" expr  (rule 4)",
          "stmt: arr '[' expr • ']' \":=\" expr  (rule 4)",
          "stmt: arr '[' expr ']' • \":=\" expr  (rule 4)",
          "stmt: arr '[' expr ']' \":=\" • expr  (rule 4)",
          "expr: • num  (rule 5)",
          "num: • num digit  (rule 8)",
          "num: num • digit  (rule 8)"
        ])
        expect(example.derivations1.render_for_report).to eq(<<~STR.chomp)
          0:  stmt                                                          "end of file"
              3: expr '?' stmt                                         stmt
                          4: arr '[' expr ']' ":=" expr
                                                   5:  num
                                                       8: num  • digit
        STR
        # Reduce Conflict
        expect(example.path2.map(&:state_item).map(&:item).map(&:to_s)).to eq([
          "$accept: • stmt \"end of file\"  (rule 0)",
          "stmt: • expr '?' stmt stmt  (rule 3)",
          "stmt: expr • '?' stmt stmt  (rule 3)",
          "stmt: expr '?' • stmt stmt  (rule 3)",
          "stmt: • arr '[' expr ']' \":=\" expr  (rule 4)",
          "stmt: arr • '[' expr ']' \":=\" expr  (rule 4)",
          "stmt: arr '[' • expr ']' \":=\" expr  (rule 4)",
          "stmt: arr '[' expr • ']' \":=\" expr  (rule 4)",
          "stmt: arr '[' expr ']' • \":=\" expr  (rule 4)",
          "stmt: arr '[' expr ']' \":=\" • expr  (rule 4)",
          "expr: • num  (rule 5)",
          "expr: num •  (rule 5)"
        ])
        expect(example.derivations2.render_for_report).to eq(<<~STR.chomp)
          0:  stmt                                                                               "end of file"
              3: expr '?' stmt                                stmt
                          4: arr '[' expr ']' ":=" expr       3:  expr             '?' stmt stmt
                                                   5: num  •      5:  num
                                                                      7:   • digit
        STR

        # State 16
        #
        #     6 expr: expr • '+' expr
        #     6     | expr '+' expr •  ["end of file", keyword_if, keyword_then, keyword_else, arr, digit, '?', ']', '+']
        #
        #     '+'  shift, and go to state 11
        #     '+'            reduce using rule 6 (expr)
        state_16 = states.states[16]
        examples = counterexamples.compute(state_16)
        expect(examples.count).to eq 1
        example = examples[0]

        expect(example.type).to eq :shift_reduce
        # Shift Conflict
        expect(example.path1.map(&:state_item).map(&:item).map(&:to_s)).to eq([
          "$accept: • stmt \"end of file\"  (rule 0)",
          "stmt: • expr '?' stmt stmt  (rule 3)",
          "expr: • expr '+' expr  (rule 6)",
          "expr: • expr '+' expr  (rule 6)",
          "expr: expr • '+' expr  (rule 6)",
          "expr: expr '+' • expr  (rule 6)",
          "expr: • expr '+' expr  (rule 6)",
          "expr: expr • '+' expr  (rule 6)"
        ])
        expect(example.derivations1.render_for_report).to eq(<<~STR.chomp)
          0:  stmt                                                           "end of file"
              3:  expr                                         '?' stmt stmt
                  6:  expr                            '+' expr
                      6: expr '+' expr
                                  6: expr  • '+' expr
        STR
        # Reduce Conflict
        expect(example.path2.map(&:state_item).map(&:item).map(&:to_s)).to eq([
          "$accept: • stmt \"end of file\"  (rule 0)",
          "stmt: • expr '?' stmt stmt  (rule 3)",
          "expr: • expr '+' expr  (rule 6)",
          "expr: • expr '+' expr  (rule 6)",
          "expr: expr • '+' expr  (rule 6)",
          "expr: expr '+' • expr  (rule 6)",
          "expr: expr '+' expr •  (rule 6)"
        ])
        expect(example.derivations2.render_for_report).to eq(<<~STR.chomp)
          0:  stmt                                                "end of file"
              3:  expr                              '?' stmt stmt
                  6:  expr                 '+' expr
                      6: expr '+' expr  •
        STR

        # State 17
        #
        #    1 stmt: keyword_if expr keyword_then stmt • keyword_else stmt
        #    2     | keyword_if expr keyword_then stmt •  ["end of file", keyword_if, keyword_else, arr, digit]
        #
        #    keyword_else  shift, and go to state 20
        #    keyword_else   reduce using rule 2 (stmt)
        state_17 = states.states[17]
        examples = counterexamples.compute(state_17)
        expect(examples.count).to eq 1
        example = examples[0]

        expect(example.type).to eq :shift_reduce
        # Shift Conflict
        expect(example.path1.map(&:state_item).map(&:item).map(&:to_s)).to eq([
          "$accept: • stmt \"end of file\"  (rule 0)",
          "stmt: • keyword_if expr keyword_then stmt keyword_else stmt  (rule 1)",
          "stmt: keyword_if • expr keyword_then stmt keyword_else stmt  (rule 1)",
          "stmt: keyword_if expr • keyword_then stmt keyword_else stmt  (rule 1)",
          "stmt: keyword_if expr keyword_then • stmt keyword_else stmt  (rule 1)",
          "stmt: • keyword_if expr keyword_then stmt keyword_else stmt  (rule 1)",
          "stmt: keyword_if • expr keyword_then stmt keyword_else stmt  (rule 1)",
          "stmt: keyword_if expr • keyword_then stmt keyword_else stmt  (rule 1)",
          "stmt: keyword_if expr keyword_then • stmt keyword_else stmt  (rule 1)",
          "stmt: keyword_if expr keyword_then stmt • keyword_else stmt  (rule 1)"
        ])
        expect(example.derivations1.render_for_report).to eq(<<~STR.chomp)
          0:  stmt                                                                                                        "end of file"
              1: keyword_if expr keyword_then stmt                                                      keyword_else stmt
                                              1: keyword_if expr keyword_then stmt  • keyword_else stmt
        STR
        # Reduce Conflict
        expect(example.path2.map(&:state_item).map(&:item).map(&:to_s)).to eq([
          "$accept: • stmt \"end of file\"  (rule 0)",
          "stmt: • keyword_if expr keyword_then stmt keyword_else stmt  (rule 1)",
          "stmt: keyword_if • expr keyword_then stmt keyword_else stmt  (rule 1)",
          "stmt: keyword_if expr • keyword_then stmt keyword_else stmt  (rule 1)",
          "stmt: keyword_if expr keyword_then • stmt keyword_else stmt  (rule 1)",
          "stmt: • keyword_if expr keyword_then stmt  (rule 2)",
          "stmt: keyword_if • expr keyword_then stmt  (rule 2)",
          "stmt: keyword_if expr • keyword_then stmt  (rule 2)",
          "stmt: keyword_if expr keyword_then • stmt  (rule 2)",
          "stmt: keyword_if expr keyword_then stmt •  (rule 2)"
        ])
        expect(example.derivations2.render_for_report).to eq(<<~STR.chomp)
          0:  stmt                                                                                       "end of file"
              1: keyword_if expr keyword_then stmt                                     keyword_else stmt
                                              2: keyword_if expr keyword_then stmt  •
        STR
      end
    end

    describe "R/R conflicts" do
      let(:y) do
        <<~STR
          %{
          // Prologue
          %}

          %union {
              int i;
          }

          %token <i> digit

          %type <i> stmt
          %type <i> expr1
          %type <i> expr2

          %%

          stmt : expr1
               | expr2
               ;

          expr1 : digit '+' digit
                ;

          expr2 : digit '+' digit
                ;

          %%

        STR
      end

      it "build counterexamples of R/R conflicts" do
        grammar = Lrama::Parser.new(y, "parse.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        counterexamples = Lrama::Counterexamples.new(states)

        # State 7
        #
        #     3 expr1: digit '+' digit •  ["end of file"]
        #     4 expr2: digit '+' digit •  ["end of file"]
        #
        #     "end of file"  reduce using rule 3 (expr1)
        #     "end of file"  reduce using rule 4 (expr2)
        state_7 = states.states[7]
        examples = counterexamples.compute(state_7)
        expect(examples.count).to eq 1
        example = examples[0]

        expect(example.type).to eq :reduce_reduce
        # Reduce Conflict
        expect(example.path1.map(&:state_item).map(&:item).map(&:to_s)).to eq([
          "$accept: • stmt \"end of file\"  (rule 0)",
          "stmt: • expr1  (rule 1)",
          "expr1: • digit '+' digit  (rule 3)",
          "expr1: digit • '+' digit  (rule 3)",
          "expr1: digit '+' • digit  (rule 3)",
          "expr1: digit '+' digit •  (rule 3)"
        ])
        expect(example.derivations1.render_for_report).to eq(<<~STR.chomp)
          0:  stmt                       "end of file"
              1:  expr1
                  3: digit '+' digit  •
        STR
        # Reduce Conflict
        expect(example.path2.map(&:state_item).map(&:item).map(&:to_s)).to eq([
          "$accept: • stmt \"end of file\"  (rule 0)",
          "stmt: • expr2  (rule 2)",
          "expr2: • digit '+' digit  (rule 4)",
          "expr2: digit • '+' digit  (rule 4)",
          "expr2: digit '+' • digit  (rule 4)",
          "expr2: digit '+' digit •  (rule 4)"
        ])
        expect(example.derivations2.render_for_report).to eq(<<~STR.chomp)
          0:  stmt                       "end of file"
              2:  expr2
                  4: digit '+' digit  •
        STR
      end

      context "when the grammar has a long rule name" do
        let(:y) do
          <<~STR
            %{
            // Prologue
            %}

            %union {
                int i;
            }

            %token <i> digit

            %type <i> stmt
            %type <i> expr1
            %type <i> long_long_long_name_expr2

            %%

            stmt : expr1
                 | long_long_long_name_expr2
                 ;

            expr1 : digit '+' digit
                  ;

            long_long_long_name_expr2 : digit '+' digit
                                      ;

            %%

          STR
        end

        it "build counterexamples of R/R conflicts" do
          grammar = Lrama::Parser.new(y, "parse.y").parse
          grammar.prepare
          grammar.validate!
          states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
          states.compute
          counterexamples = Lrama::Counterexamples.new(states)

          # State 7
          #
          #     3 expr1: digit '+' digit •  ["end of file"]
          #     4 long_long_long_name_expr2: digit '+' digit •  ["end of file"]
          #
          #     "end of file"  reduce using rule 3 (expr1)
          #     "end of file"  reduce using rule 4 (long_long_long_name_expr2)
          state_7 = states.states[7]
          examples = counterexamples.compute(state_7)
          expect(examples.count).to eq 1
          example = examples[0]

          expect(example.type).to eq :reduce_reduce
          # Reduce Conflict
          expect(example.path1.map(&:state_item).map(&:item).map(&:to_s)).to eq([
            "$accept: • stmt \"end of file\"  (rule 0)",
            "stmt: • expr1  (rule 1)",
            "expr1: • digit '+' digit  (rule 3)",
            "expr1: digit • '+' digit  (rule 3)",
            "expr1: digit '+' • digit  (rule 3)",
            "expr1: digit '+' digit •  (rule 3)"
          ])
          expect(example.derivations1.render_for_report).to eq(<<~STR.chomp)
            0:  stmt                       "end of file"
                1:  expr1
                    3: digit '+' digit  •
          STR
          # Reduce Conflict
          expect(example.path2.map(&:state_item).map(&:item).map(&:to_s)).to eq([
            "$accept: • stmt \"end of file\"  (rule 0)",
            "stmt: • long_long_long_name_expr2  (rule 2)",
            "long_long_long_name_expr2: • digit '+' digit  (rule 4)",
            "long_long_long_name_expr2: digit • '+' digit  (rule 4)",
            "long_long_long_name_expr2: digit '+' • digit  (rule 4)",
            "long_long_long_name_expr2: digit '+' digit •  (rule 4)"
          ])
          expect(example.derivations2.render_for_report).to eq(<<~STR.chomp)
            0:  stmt                         "end of file"
                2:  long_long_long_name_expr2
                    4: digit '+' digit  •
          STR
        end
      end
    end

    describe "target state item will be start item when finding shift conflict shortest state items" do
      let(:y) do
        <<~STR
          %{
          // Prologue
          %}

          %union {
              int i;
          }

          %token digit

          %%

          stmt : expr '+'
               ;

          expr : digit '+' digit
               | digit
               ;

          %%

        STR
      end

      it "build counterexamples of S/R conflicts" do
        grammar = Lrama::Parser.new(y, "parse.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        counterexamples = Lrama::Counterexamples.new(states)

        # State 1
        #
        #     2 expr: digit • '+' digit
        #     3     | digit •  ['+']
        #
        #     '+'  shift, and go to state 4
        #     '+'  reduce using rule 3 (expr)
        state_1 = states.states[1]
        examples = counterexamples.compute(state_1)
        expect(examples.count).to eq 1
        example = examples[0]

        expect(example.type).to eq :shift_reduce
        # Shift Conflict
        expect(example.path1.map(&:state_item).map(&:item).map(&:to_s)).to eq([
          "$accept: • stmt \"end of file\"  (rule 0)",
          "stmt: • expr '+'  (rule 1)",
          "expr: • digit '+' digit  (rule 2)",
          "expr: digit • '+' digit  (rule 2)"
        ])
        expect(example.derivations1.render_for_report).to eq(<<~STR.chomp)
          0:  stmt                          "end of file"
              1:  expr                  '+'
                  2: digit  • '+' digit
        STR
        # Reduce Conflict
        expect(example.path2.map(&:state_item).map(&:item).map(&:to_s)).to eq([
          "$accept: • stmt \"end of file\"  (rule 0)",
          "stmt: • expr '+'  (rule 1)",
          "expr: • digit  (rule 3)",
          "expr: digit •  (rule 3)"
        ])
        expect(example.derivations2.render_for_report).to eq(<<~STR.chomp)
          0:  stmt                 "end of file"
              1:  expr         '+'
                  3: digit  •
        STR
      end
    end

    describe "derivation's next symbol is nullable" do
      let(:y) do
        <<~STR
          %{
          // Prologue
          %}

          %union {
              int i;
          }

          %token <i> digit

          %%

          stmt : expr
               ;

          expr : num
               | expr opt_nl '+' expr
               ;

          num  : digit
               | num digit
               ;

          opt_nl : /* none */
                 | '\\n'
                 ;

          %%

        STR
      end

      it "build counterexamples of S/R and R/R conflicts" do
        grammar = Lrama::Parser.new(y, "parse.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        counterexamples = Lrama::Counterexamples.new(states)

        # State 10
        #
        #     3 expr: expr • opt_nl '+' expr
        #     3     | expr opt_nl '+' expr •  ["end of file", '+', '\n']
        #     6 opt_nl: ε •  ['+']
        #     7       | • '\n'
        #
        #     '\n'  shift, and go to state 6
        #     '\n'           reduce using rule 3 (expr)
        #
        #     '+'            reduce using rule 3 (expr)
        #     '+'            reduce using rule 6 (opt_nl)
        state_10 = states.states[10]
        examples = counterexamples.compute(state_10)
        expect(examples.count).to eq 2
        example = examples[0]

        expect(example.type).to eq :shift_reduce
        expect(example.conflict_symbol.id.s_value).to eq "'\\n'"
        # Shift Conflict
        expect(example.path1.map(&:state_item).map(&:item).map(&:to_s)).to eq([
          "$accept: • stmt \"end of file\"  (rule 0)",
          "stmt: • expr  (rule 1)",
          "expr: • expr opt_nl '+' expr  (rule 3)",
          "expr: • expr opt_nl '+' expr  (rule 3)",
          "expr: expr • opt_nl '+' expr  (rule 3)",
          "expr: expr opt_nl • '+' expr  (rule 3)",
          "expr: expr opt_nl '+' • expr  (rule 3)",
          "expr: • expr opt_nl '+' expr  (rule 3)",
          "expr: expr • opt_nl '+' expr  (rule 3)",
          "opt_nl: • '\\n'  (rule 7)"
        ])
        expect(example.derivations1.render_for_report).to eq(<<~STR.chomp)
          0:  stmt                                                                    "end of file"
              1:  expr
                  3:  expr                                            opt_nl '+' expr
                      3: expr opt_nl '+' expr
                                         3: expr opt_nl      '+' expr
                                                 7:   • '\\n'
        STR
        # Reduce Conflict
        expect(example.path2.map(&:state_item).map(&:item).map(&:to_s)).to eq([
          "$accept: • stmt \"end of file\"  (rule 0)",
          "stmt: • expr  (rule 1)",
          "expr: • expr opt_nl '+' expr  (rule 3)",
          "expr: • expr opt_nl '+' expr  (rule 3)",
          "expr: expr • opt_nl '+' expr  (rule 3)",
          "expr: expr opt_nl • '+' expr  (rule 3)",
          "expr: expr opt_nl '+' • expr  (rule 3)",
          "expr: expr opt_nl '+' expr •  (rule 3)"
        ])
        expect(example.derivations2.render_for_report).to eq(<<~STR.chomp)
          0:  stmt                                                "end of file"
              1:  expr
                  3:  expr                        opt_nl '+' expr
                      3: expr opt_nl '+' expr  •  7:   • '\\n'
        STR

        example = examples[1]

        expect(example.type).to eq :reduce_reduce
        expect(example.conflict_symbol.id.s_value).to eq "'+'"
        # Reduce Conflict
        expect(example.path1.map(&:state_item).map(&:item).map(&:to_s)).to eq([
          "$accept: • stmt \"end of file\"  (rule 0)",
          "stmt: • expr  (rule 1)",
          "expr: • expr opt_nl '+' expr  (rule 3)",
          "expr: • expr opt_nl '+' expr  (rule 3)",
          "expr: expr • opt_nl '+' expr  (rule 3)",
          "expr: expr opt_nl • '+' expr  (rule 3)",
          "expr: expr opt_nl '+' • expr  (rule 3)",
          "expr: expr opt_nl '+' expr •  (rule 3)"
        ])
        expect(example.derivations1.render_for_report).to eq(<<~STR.chomp)
          0:  stmt                                                "end of file"
              1:  expr
                  3:  expr                        opt_nl '+' expr
                      3: expr opt_nl '+' expr  •
        STR
        # Reduce Conflict
        expect(example.path2.map(&:state_item).map(&:item).map(&:to_s)).to eq([
          "$accept: • stmt \"end of file\"  (rule 0)",
          "stmt: • expr  (rule 1)",
          "expr: • expr opt_nl '+' expr  (rule 3)",
          "expr: expr • opt_nl '+' expr  (rule 3)",
          "expr: expr opt_nl • '+' expr  (rule 3)",
          "expr: expr opt_nl '+' • expr  (rule 3)",
          "expr: • expr opt_nl '+' expr  (rule 3)",
          "expr: expr • opt_nl '+' expr  (rule 3)",
          "opt_nl: •  (rule 6)"
        ])
        expect(example.derivations2.render_for_report).to eq(<<~STR.chomp)
          0:  stmt                                            "end of file"
              1:  expr
                  3: expr opt_nl '+' expr
                                     3: expr opt_nl  '+' expr
                                             6:   •
        STR
      end
    end
  end
end
