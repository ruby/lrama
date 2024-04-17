RSpec.describe Lrama::Grammar::Code do
  let(:token_class) { Lrama::Lexer::Token }
  let(:user_code_dollar_dollar) { token_class::UserCode.new(s_value: 'print($$);') }
  let(:user_code_at_dollar) { token_class::UserCode.new(s_value: 'print(@$);') }
  let(:user_code_index_dollar) { token_class::UserCode.new(s_value: 'print($:$);') }
  let(:user_code_dollar_n) { token_class::UserCode.new(s_value: 'print($n);') }
  let(:user_code_at_n) { token_class::UserCode.new(s_value: 'print(@n);') }
  let(:user_code_index_n) { token_class::UserCode.new(s_value: 'print($:1);') }

  describe Lrama::Grammar::Code::InitialActionCode do
    describe "#translated_code" do
      it "translats '$$' to 'yylval'" do
        code = described_class.new(type: :initial_action, token_code: user_code_dollar_dollar)
        expect(code.translated_code).to eq("print(yylval);")
      end

      it "translats '@$' to 'yylloc'" do
        code = described_class.new(type: :initial_action, token_code: user_code_at_dollar)
        expect(code.translated_code).to eq("print(yylloc);")
      end

      it "raises error for '$:$'" do
        code = described_class.new(type: :initial_action, token_code: user_code_index_dollar)
        expect { code.translated_code }.to raise_error("$:$ can not be used in initial_action.")
      end

      it "raises error for '$n'" do
        code = described_class.new(type: :initial_action, token_code: user_code_dollar_n)
        expect { code.translated_code }.to raise_error("$n can not be used in initial_action.")
      end

      it "raises error for '@n'" do
        code = described_class.new(type: :initial_action, token_code: user_code_at_n)
        expect { code.translated_code }.to raise_error("@n can not be used in initial_action.")
      end

      it "raises error for '$:n'" do
        code = described_class.new(type: :initial_action, token_code: user_code_index_n)
        expect { code.translated_code }.to raise_error("$:1 can not be used in initial_action.")
      end
    end
  end

  describe Lrama::Grammar::Code::NoReferenceCode do
    describe "#translated_code" do
      it "raises error for '$$'" do
        code = described_class.new(type: :union, token_code: user_code_dollar_dollar)
        expect { code.translated_code }.to raise_error("$$ can not be used in union.")
      end

      it "raises error for '@$'" do
        code = described_class.new(type: :union, token_code: user_code_at_dollar)
        expect { code.translated_code }.to raise_error("@$ can not be used in union.")
      end

      it "raises error for '$:$'" do
        code = described_class.new(type: :union, token_code: user_code_index_dollar)
        expect { code.translated_code }.to raise_error("$:$ can not be used in union.")
      end

      it "raises error for '$n'" do
        code = described_class.new(type: :union, token_code: user_code_dollar_n)
        expect { code.translated_code }.to raise_error("$n can not be used in union.")
      end

      it "raises error for '@n'" do
        code = described_class.new(type: :union, token_code: user_code_at_n)
        expect { code.translated_code }.to raise_error("@n can not be used in union.")
      end

      it "raises error for '$:n'" do
        code = described_class.new(type: :union, token_code: user_code_index_n)
        expect { code.translated_code }.to raise_error("$:1 can not be used in union.")
      end
    end
  end

  describe Lrama::Grammar::Code::DestructorCode do
    describe "#translated_code" do
      let(:tag) { token_class::Tag.new(s_value: '<val>') }

      it "translats '$$' to '((*yyvaluep).val)'" do
        code = described_class.new(type: :destructor, token_code: user_code_dollar_dollar, tag: tag)
        expect(code.translated_code).to eq("print(((*yyvaluep).val));")
      end

      it "translats '@$' to '(*yylocationp)'" do
        code = described_class.new(type: :destructor, token_code: user_code_at_dollar, tag: tag)
        expect(code.translated_code).to eq("print((*yylocationp));")
      end

      it "raises error for '$:$'" do
        code = described_class.new(type: :destructor, token_code: user_code_index_dollar, tag: tag)
        expect { code.translated_code }.to raise_error("$:$ can not be used in destructor.")
      end

      it "raises error for '$n'" do
        code = described_class.new(type: :destructor, token_code: user_code_dollar_n, tag: tag)
        expect { code.translated_code }.to raise_error("$n can not be used in destructor.")
      end

      it "raises error for '@n'" do
        code = described_class.new(type: :destructor, token_code: user_code_at_n, tag: tag)
        expect { code.translated_code }.to raise_error("@n can not be used in destructor.")
      end

      it "raises error for '$:n'" do
        code = described_class.new(type: :destructor, token_code: user_code_index_n, tag: tag)
        expect { code.translated_code }.to raise_error("$:1 can not be used in destructor.")
      end
    end
  end

  describe Lrama::Grammar::Code::PrinterCode do
    describe "#translated_code" do
      let(:tag) { token_class::Tag.new(s_value: '<val>') }

      it "translats '$$' to '((*yyvaluep).val)'" do
        code = described_class.new(type: :printer, token_code: user_code_dollar_dollar, tag: tag)
        expect(code.translated_code).to eq("print(((*yyvaluep).val));")
      end

      it "translats '@$' to '(*yylocationp)'" do
        code = described_class.new(type: :printer, token_code: user_code_at_dollar, tag: tag)
        expect(code.translated_code).to eq("print((*yylocationp));")
      end

      it "raises error for '$:$'" do
        code = described_class.new(type: :printer, token_code: user_code_index_dollar, tag: tag)
        expect { code.translated_code }.to raise_error("$:$ can not be used in printer.")
      end

      it "raises error for '$n'" do
        code = described_class.new(type: :printer, token_code: user_code_dollar_n, tag: tag)
        expect { code.translated_code }.to raise_error("$n can not be used in printer.")
      end

      it "raises error for '@n'" do
        code = described_class.new(type: :printer, token_code: user_code_at_n, tag: tag)
        expect { code.translated_code }.to raise_error("@n can not be used in printer.")
      end

      it "raises error for '$:n'" do
        code = described_class.new(type: :printer, token_code: user_code_index_n, tag: tag)
        expect { code.translated_code }.to raise_error("$:1 can not be used in printer.")
      end
    end
  end

  describe Lrama::Grammar::Code::RuleAction do
    let(:y) do
      <<~GRAMMAR
        %union {
            int i;
            int str;
            int l;
            int expr;
            int integer;
            int rule1;
            int rule2;
            int rule3;
            int rule4;
            int rule5;
            int rule6;
            int rule7;
        }

        %token <i> keyword_class
        %token <str> tSTRING
        %token <l> keyword_end
        %token <expr> expr

        %type <rule1> rule1
        %type <rule2> rule2
        %type <rule3> rule3
        %type <rule4> rule4
        %type <rule5> rule5
        %type <rule6> rule6
        %type <rule7> rule7

        %%

        program: rule1
               | rule2
               | rule3
               | rule4
               | rule5
               | rule6
               | rule7
               | rule8
               | rule9
               | rule10
               | rule11
               | rule12
               | rule13
               ;

        rule1: expr '+' expr { $$ = 0; }
             ;

        rule2: expr '+' expr { @$ = 0; }
             ;

        rule3: expr '+' expr[expr-right] { $1 + $[expr-right]; }
             ;

        rule4: expr '+' expr[expr-right] { @1 + @[expr-right]; @0; }
             ;

        rule5: expr '+' expr { $1 + $<integer>3; }
             ;

        rule6: expr '+' { $<integer>$ = $1; @$ = @1; } expr { $1 + $<integer>4; }
             ;

        rule7: expr { $$ = $1 } '+' expr { $2; }
             ;

        rule8: expr { $$ = $1 } '+' expr { $2; }
             ;

        rule9: expr '+' expr { $:1; $:2; $:3; }
             ;

        rule10: expr '+' expr { $:$; }
              ;

        rule11: expr { $:1; } '+' expr { $:1; $:2; $:3; $:4; }
              ;

        rule12: expr '+' expr[expr-right] { $:1; $:2; $:[expr-right]; }
              ;

        rule13: expr '+' { $$ = $1; @$ = @1; }<integer> expr { $1 + $3; }
              ;
        %%
      GRAMMAR
    end
    let(:grammar) do
      grammar = Lrama::Parser.new(y, "parse.y").parse
      grammar.prepare
      grammar.validate!
      grammar
    end

    describe "#translated_code" do
      it "translats '$$' to '(yyval)' with member" do
        code = grammar.rules.find {|r| r.lhs.id.s_value == "rule1" }
        expect(code.translated_code).to eq(" (yyval.rule1) = 0; ")
      end

      it "translats '@$' to '(yyloc)'" do
        code = grammar.rules.find {|r| r.lhs.id.s_value == "rule2" }
        expect(code.translated_code).to eq(" (yyloc) = 0; ")
      end

      it "translats '$n' to '(yyvsp)' with index and member" do
        code = grammar.rules.find {|r| r.lhs.id.s_value == "rule3" }
        expect(code.translated_code).to eq(" (yyvsp[-2].expr) + (yyvsp[0].expr); ")
      end

      it "translats '@n' to '(yylsp)' with index" do
        code = grammar.rules.find {|r| r.lhs.id.s_value == "rule4" }
        expect(code.translated_code).to eq(" (yylsp[-2]) + (yylsp[0]); (yylsp[-3]); ")
      end

      it "respects explicit tag in a rule" do
        code = grammar.rules.find {|r| r.lhs.id.s_value == "rule5" }
        expect(code.translated_code).to eq(" (yyvsp[-2].expr) + (yyvsp[0].integer); ")
      end

      context "midrule action exists" do
        it "uses index on the original rule (-1)" do
          # midrule action in rule6
          code = grammar.rules.find {|r| r.lhs.id.s_value == "$@1" }
          expect(code.translated_code).to eq(" (yyval.integer) = (yyvsp[-1].expr); (yyloc) = (yylsp[-1]); ")

          code = grammar.rules.find {|r| r.lhs.id.s_value == "rule6" }
          expect(code.translated_code).to eq(" (yyvsp[-3].expr) + (yyvsp[0].integer); ")
        end

        it "uses an explicit tag for type casting" do
          # midrule action in rule13
          code = grammar.rules.find {|r| r.lhs.id.s_value == "@5" }
          expect(code.translated_code).to eq(" (yyval.integer) = (yyvsp[-1].expr); (yyloc) = (yylsp[-1]); ")

          code = grammar.rules.find {|r| r.lhs.id.s_value == "rule13" }
          expect(code.translated_code).to eq(" (yyvsp[-3].expr) + (yyvsp[-1].integer); ")
        end
      end

      context "can not resolve tag of references" do
        it "raises error" do
          # midrule action in rule7
          # rule7 has tag
          code = grammar.rules.find {|r| r.lhs.id.s_value == "@2" }
          expect { code.translated_code }.to raise_error("Tag is not specified for '$$' in '@2 -> ε'")

          code = grammar.rules.find {|r| r.lhs.id.s_value == "rule7" }
          expect { code.translated_code }.to raise_error("Tag is not specified for '$2' in 'rule7 -> expr @2 '+' expr'")

          # midrule action in rule8
          # rule8 has no tag
          code = grammar.rules.find {|r| r.lhs.id.s_value == "@3" }
          expect { code.translated_code }.to raise_error("Tag is not specified for '$$' in '@3 -> ε'")

          code = grammar.rules.find {|r| r.lhs.id.s_value == "rule8" }
          expect { code.translated_code }.to raise_error("Tag is not specified for '$2' in 'rule8 -> expr @3 '+' expr'")
        end
      end

      context "$: is used" do
        it "translats '$:$' to '-yylen' and '$:n' to index from the last of array" do
          code = grammar.rules.find {|r| r.lhs.id.s_value == "rule9" }
          expect(code.translated_code).to eq(" (-2 - 1); (-1 - 1); (0 - 1); ")

          code = grammar.rules.find {|r| r.lhs.id.s_value == "rule10" }
          expect { code.translated_code }.to raise_error("$:$ is not supported")

          # midrule action in rule11
          code = grammar.rules.find {|r| r.lhs.id.s_value == "@4" }
          expect(code.translated_code).to eq(" (0 - 1); ")

          code = grammar.rules.find {|r| r.lhs.id.s_value == "rule11" }
          expect(code.translated_code).to eq(" (-3 - 1); (-2 - 1); (-1 - 1); (0 - 1); ")

          code = grammar.rules.find {|r| r.lhs.id.s_value == "rule12" }
          expect(code.translated_code).to eq(" (-2 - 1); (-1 - 1); (0 - 1); ")
        end
      end
    end
  end
end
