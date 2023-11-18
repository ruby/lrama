RSpec.describe Lrama::Grammar::RuleBuilder do
  let(:rule_counter) { Lrama::Grammar::Counter.new(1) }
  let(:midrule_action_counter) { Lrama::Grammar::Counter.new(1) }
  let(:rule_builder) { Lrama::Grammar::RuleBuilder.new(rule_counter, midrule_action_counter) }

  describe "#add_rhs" do
    describe "@line" do
      let(:location) { Lrama::Lexer::Location.new(first_line: 1, first_column: 0, last_line: 1, last_column: 4) }
      let(:token) { Lrama::Lexer::Token::Ident.new(s_value: "class", location: location) }

      context "@line is nil" do
        it "sets rhs.line to @line" do
          # Assertion
          expect(rule_builder.line).to be nil

          rule_builder.add_rhs(token)
          expect(rule_builder.line).to eq 1
        end
      end

      context "@line is not nil" do
        it "doesn't change @line" do
          rule_builder.line = 0
          # Assertion
          expect(rule_builder.line).to eq 0

          rule_builder.add_rhs(token)
          expect(rule_builder.line).to eq 0
        end
      end
    end
  end

  describe "#user_code=" do
    describe "@user_code" do
      let(:location) { Lrama::Lexer::Location.new(first_line: 1, first_column: 0, last_line: 1, last_column: 4) }
      let(:token_1) { Lrama::Lexer::Token::UserCode.new(s_value: "code 1", location: location) }
      let(:token_2) { Lrama::Lexer::Token::UserCode.new(s_value: "code 2", location: location) }

      context "@user_code is nil" do
        it "sets @user_code and doesn't add user_code to rhs" do
          # Assertion
          expect(rule_builder.rhs).to eq([])

          rule_builder.user_code = token_1
          expect(rule_builder.user_code).to eq token_1
          expect(rule_builder.rhs).to eq([])
        end
      end

      context "@user_code is not nil" do
        it "sets @user_code and add previous user_code to rhs" do
          # Assertion
          rule_builder.user_code = token_1
          expect(rule_builder.rhs).to eq([])

          rule_builder.user_code = token_2
          expect(rule_builder.user_code).to eq token_2
          expect(rule_builder.rhs).to eq([token_1])
        end
      end
    end

    describe "@line" do
      let(:location) { Lrama::Lexer::Location.new(first_line: 1, first_column: 0, last_line: 1, last_column: 4) }
      let(:token) { Lrama::Lexer::Token::UserCode.new(s_value: "code 1", location: location) }

      context "@line is nil" do
        it "sets rhs.line to @line" do
          # Assertion
          expect(rule_builder.line).to be nil

          rule_builder.user_code = token
          expect(rule_builder.line).to eq 1
        end
      end

      context "@line is not nil" do
        it "doesn't change @line" do
          rule_builder.line = 0
          # Assertion
          expect(rule_builder.line).to eq 0

          rule_builder.user_code = token
          expect(rule_builder.line).to eq 0
        end
      end
    end
  end

  describe "#precedence_sym=" do
    describe "@user_code" do
      let(:location) { Lrama::Lexer::Location.new(first_line: 1, first_column: 0, last_line: 1, last_column: 4) }
      let(:token_1) { Lrama::Lexer::Token::UserCode.new(s_value: "code 1", location: location) }
      let(:sym) { Lrama::Grammar::Symbol.new(id: Lrama::Lexer::Token::Ident.new(s_value: "tPLUS")) }

      context "@user_code is not nil" do
        it "sets @user_code to be nil and add previous user_code to rhs" do
          # Assertion
          rule_builder.user_code = token_1
          expect(rule_builder.rhs).to eq([])

          rule_builder.precedence_sym = sym
          expect(rule_builder.user_code).to be nil
          expect(rule_builder.rhs).to eq([token_1])
        end
      end
    end
  end

  describe "#freeze_rhs" do
    let(:location) { Lrama::Lexer::Location.new(first_line: 1, first_column: 0, last_line: 1, last_column: 4) }
    let(:token) { Lrama::Lexer::Token::Ident.new(s_value: "class", location: location) }

    it "can not add rhs after #freeze_rhs is called" do
      rule_builder.add_rhs(token)
      rule_builder.send(:freeze_rhs)
      expect { rule_builder.add_rhs(token) }.to raise_error(FrozenError)
    end
  end

  describe "#preprocess_references" do
    context "variables refer to correct name and correct position" do
      let(:location) { Lrama::Lexer::Location.new(first_line: 1, first_column: 0, last_line: 1, last_column: 4) }
      let(:token_1) { Lrama::Lexer::Token::Ident.new(s_value: "class", location: location) }
      let(:token_2) { Lrama::Lexer::Token::Ident.new(s_value: "keyword_class", location: location) }
      let(:token_3) { Lrama::Lexer::Token::Ident.new(s_value: "tSTRING", location: location) }
      let(:token_4) { Lrama::Lexer::Token::Ident.new(s_value: "keyword_end", location: location) }
      let(:token_5) { Lrama::Lexer::Token::UserCode.new(s_value: "$class = $1 + $keyword_end; @class = @1 + @keyword_end;", location: location) }

      it "resolves index of references and fills its value with index" do
        # class : keyword_class tSTRING keyword_end { $class = $1 + $keyword_end; @class = @1 + @keyword_end; }
        rule_builder.lhs = token_1
        rule_builder.add_rhs(token_2)
        rule_builder.add_rhs(token_3)
        rule_builder.add_rhs(token_4)
        rule_builder.user_code = token_5
        rule_builder.complete_input

        rule_builder.send(:preprocess_references)

        expect(token_5.references.count).to eq 6
        expect(token_5.references[0].type).to eq :dollar
        expect(token_5.references[0].name).to eq '$'
        expect(token_5.references[0].index).to eq nil

        expect(token_5.references[1].type).to eq :dollar
        expect(token_5.references[1].name).to eq nil
        expect(token_5.references[1].index).to eq 1

        expect(token_5.references[2].type).to eq :dollar
        expect(token_5.references[2].name).to eq 'keyword_end'
        expect(token_5.references[2].index).to eq 3

        expect(token_5.references[3].type).to eq :at
        expect(token_5.references[3].name).to eq '$'
        expect(token_5.references[3].index).to eq nil

        expect(token_5.references[4].type).to eq :at
        expect(token_5.references[4].name).to eq nil
        expect(token_5.references[4].index).to eq 1

        expect(token_5.references[5].type).to eq :at
        expect(token_5.references[5].name).to eq 'keyword_end'
        expect(token_5.references[5].index).to eq 3
      end
    end

    context "variables in mid action rule refer to correct name and correct position" do
      let(:location) { Lrama::Lexer::Location.new(first_line: 1, first_column: 0, last_line: 1, last_column: 4) }
      let(:token_1) { Lrama::Lexer::Token::Ident.new(s_value: "class", location: location) }
      let(:token_2) { Lrama::Lexer::Token::Ident.new(s_value: "keyword_class", location: location) }
      let(:token_3) { Lrama::Lexer::Token::Ident.new(s_value: "tSTRING", location: location) }
      let(:token_4) { Lrama::Lexer::Token::UserCode.new(s_value: "$$ = $keyword_class + $2; @$ = @keyword_class + @2;", location: location) }
      let(:token_5) { Lrama::Lexer::Token::Ident.new(s_value: "keyword_end", location: location) }

      it "raises error" do
        # class : keyword_class tSTRING { $$ = $keyword_class + $2; @$ = @keyword_class + @2; } keyword_end
        rule_builder.lhs = token_1
        rule_builder.add_rhs(token_2)
        rule_builder.add_rhs(token_3)
        rule_builder.user_code = token_4
        rule_builder.add_rhs(token_5)
        rule_builder.complete_input

        rule_builder.send(:preprocess_references)

        expect(token_4.references.count).to eq 6
        expect(token_4.references[0].type).to eq :dollar
        expect(token_4.references[0].name).to eq '$'
        expect(token_4.references[0].index).to eq nil

        expect(token_4.references[1].type).to eq :dollar
        expect(token_4.references[1].name).to eq 'keyword_class'
        expect(token_4.references[1].index).to eq 1

        expect(token_4.references[2].type).to eq :dollar
        expect(token_4.references[2].name).to eq nil
        expect(token_4.references[2].index).to eq 2

        expect(token_4.references[3].type).to eq :at
        expect(token_4.references[3].name).to eq '$'
        expect(token_4.references[3].index).to eq nil

        expect(token_4.references[4].type).to eq :at
        expect(token_4.references[4].name).to eq 'keyword_class'
        expect(token_4.references[4].index).to eq 1

        expect(token_4.references[5].type).to eq :at
        expect(token_4.references[5].name).to eq nil
        expect(token_4.references[5].index).to eq 2
      end
    end

    context "variables refer to wrong position" do
      let(:location) { Lrama::Lexer::Location.new(first_line: 1, first_column: 0, last_line: 1, last_column: 4) }
      let(:token_1) { Lrama::Lexer::Token::Ident.new(s_value: "class", location: location) }
      let(:token_2) { Lrama::Lexer::Token::Ident.new(s_value: "keyword_class", location: location) }
      let(:token_3) { Lrama::Lexer::Token::Ident.new(s_value: "tSTRING", location: location) }
      let(:token_4) { Lrama::Lexer::Token::Ident.new(s_value: "keyword_end", location: location) }
      let(:token_5) { Lrama::Lexer::Token::UserCode.new(s_value: "$class = $10;", location: location) }

      it "raises error" do
        # class : keyword_class tSTRING keyword_end { $class = $10; }
        rule_builder.lhs = token_1
        rule_builder.add_rhs(token_2)
        rule_builder.add_rhs(token_3)
        rule_builder.add_rhs(token_4)
        rule_builder.user_code = token_5
        rule_builder.complete_input

        expect { rule_builder.send(:preprocess_references) }.to raise_error(/Can not refer following component\. 10 >= 4\./)
      end
    end

    context "variables in mid action rule refer to following component" do
      let(:location) { Lrama::Lexer::Location.new(first_line: 1, first_column: 0, last_line: 1, last_column: 4) }
      let(:token_1) { Lrama::Lexer::Token::Ident.new(s_value: "class", location: location) }
      let(:token_2) { Lrama::Lexer::Token::Ident.new(s_value: "keyword_class", location: location) }
      let(:token_3) { Lrama::Lexer::Token::UserCode.new(s_value: "$3;", location: location) }
      let(:token_4) { Lrama::Lexer::Token::Ident.new(s_value: "tSTRING", location: location) }
      let(:token_5) { Lrama::Lexer::Token::Ident.new(s_value: "keyword_end", location: location) }
      let(:token_6) { Lrama::Lexer::Token::UserCode.new(s_value: "$class = $1;", location: location) }

      it "raises error" do
        # class : keyword_class { $3; } tSTRING keyword_end { $class = $1; }
        rule_builder.lhs = token_1
        rule_builder.add_rhs(token_2)
        rule_builder.user_code = token_3
        rule_builder.add_rhs(token_4)
        rule_builder.add_rhs(token_5)
        rule_builder.user_code = token_6
        rule_builder.complete_input

        expect { rule_builder.send(:preprocess_references) }.to raise_error(/Can not refer following component\. 3 >= 2\./)
      end
    end

    context "variables refer with wrong name" do
      let(:location) { Lrama::Lexer::Location.new(first_line: 1, first_column: 0, last_line: 1, last_column: 4) }
      let(:token_1) { Lrama::Lexer::Token::Ident.new(s_value: "class", location: location) }
      let(:token_2) { Lrama::Lexer::Token::Ident.new(s_value: "keyword_class", location: location) }
      let(:token_3) { Lrama::Lexer::Token::Ident.new(s_value: "tSTRING", location: location) }
      let(:token_4) { Lrama::Lexer::Token::Ident.new(s_value: "keyword_end", location: location) }
      let(:token_5) { Lrama::Lexer::Token::UserCode.new(s_value: "$classes = $1;", location: location) }

      it "raises error" do
        # class : keyword_class tSTRING keyword_end { $classes = $1; }
        rule_builder.lhs = token_1
        rule_builder.add_rhs(token_2)
        rule_builder.add_rhs(token_3)
        rule_builder.add_rhs(token_4)
        rule_builder.user_code = token_5
        rule_builder.complete_input

        expect { rule_builder.send(:preprocess_references) }.to raise_error(/Referring symbol `classes` is not found\./)
      end
    end

    context "component name is duplicated" do
      let(:location) { Lrama::Lexer::Location.new(first_line: 1, first_column: 0, last_line: 1, last_column: 4) }
      let(:token_1) { Lrama::Lexer::Token::Ident.new(s_value: "class", location: location) }
      let(:token_2) { Lrama::Lexer::Token::Ident.new(s_value: "keyword_class", location: location) }
      let(:token_3) { Lrama::Lexer::Token::Ident.new(s_value: "tSTRING", location: location) }
      let(:token_4) { Lrama::Lexer::Token::Ident.new(s_value: "tSTRING", location: location) }
      let(:token_5) { Lrama::Lexer::Token::Ident.new(s_value: "keyword_end", location: location) }
      let(:token_6) { Lrama::Lexer::Token::UserCode.new(s_value: "$class = $tSTRING;", location: location) }

      it "raises error" do
        # class : keyword_class tSTRING tSTRING keyword_end { $class = $tSTRING; }
        rule_builder.lhs = token_1
        rule_builder.add_rhs(token_2)
        rule_builder.add_rhs(token_3)
        rule_builder.add_rhs(token_4)
        rule_builder.add_rhs(token_5)
        rule_builder.user_code = token_6
        rule_builder.complete_input

        expect { rule_builder.send(:preprocess_references) }.to raise_error(/Referring symbol `tSTRING` is duplicated\./)
      end
    end
  end

  describe "#midrule_action_rules" do
    let(:location) { Lrama::Lexer::Location.new(first_line: 1, first_column: 0, last_line: 1, last_column: 4) }
    let(:token_1) { Lrama::Lexer::Token::Ident.new(s_value: "class", location: location) }
    let(:token_2) { Lrama::Lexer::Token::Ident.new(s_value: "keyword_class", location: location) }
    let(:token_3) { Lrama::Lexer::Token::UserCode.new(s_value: "$1", location: location) }
    let(:token_4) { Lrama::Lexer::Token::Ident.new(s_value: "tSTRING", location: location) }
    let(:token_5) { Lrama::Lexer::Token::UserCode.new(s_value: "$2 + $3", location: location) }
    let(:token_6) { Lrama::Lexer::Token::Ident.new(s_value: "keyword_end", location: location) }
    let(:token_7) { Lrama::Lexer::Token::UserCode.new(s_value: "$class = $1 + $keyword_end", location: location) }

    it "builds rules from midrule actions" do
      # class : keyword_class { $1 } tSTRING { $2 + $3 } keyword_end { $class = $1 + $keyword_end }
      rule_builder.lhs = token_1
      rule_builder.add_rhs(token_2)
      rule_builder.user_code = token_3
      rule_builder.add_rhs(token_4)
      rule_builder.user_code = token_5
      rule_builder.add_rhs(token_6)
      rule_builder.user_code = token_7
      rule_builder.complete_input
      rule_builder.setup_rules

      rule = rule_builder.rules.first
      rules = rule_builder.midrule_action_rules

      expect(rules.count).to eq 2
      expect(rules[0]._lhs.s_value).to eq '@1'
      expect(rules[0].token_code.s_value).to eq '$1'
      expect(rules[0].original_rule).to eq rule
      expect(rules[1]._lhs.s_value).to eq '$@2'
      expect(rules[1].token_code.s_value).to eq '$2 + $3'
      expect(rules[1].original_rule).to eq rule
    end
  end

  describe "@replaced_rhs" do
    let(:location) { Lrama::Lexer::Location.new(first_line: 1, first_column: 0, last_line: 1, last_column: 4) }
    let(:token_1) { Lrama::Lexer::Token::Ident.new(s_value: "class", location: location) }
    let(:token_2) { Lrama::Lexer::Token::Ident.new(s_value: "keyword_class", location: location) }
    let(:token_3) { Lrama::Lexer::Token::UserCode.new(s_value: "$1", location: location) }
    let(:token_4) { Lrama::Lexer::Token::Ident.new(s_value: "tSTRING", location: location) }
    let(:token_5) { Lrama::Lexer::Token::UserCode.new(s_value: "$2 + $3", location: location) }
    let(:token_6) { Lrama::Lexer::Token::Ident.new(s_value: "keyword_end", location: location) }
    let(:token_7) { Lrama::Lexer::Token::UserCode.new(s_value: "$class = $1 + $keyword_end", location: location) }

    it "is a token list whose user codes are replaced with @n token" do
      # class : keyword_class { $1 } tSTRING { $2 + $3 } keyword_end { $class = $1 + $keyword_end }
      rule_builder.lhs = token_1
      rule_builder.add_rhs(token_2)
      rule_builder.user_code = token_3
      rule_builder.add_rhs(token_4)
      rule_builder.user_code = token_5
      rule_builder.add_rhs(token_6)
      rule_builder.user_code = token_7
      rule_builder.complete_input
      rule_builder.setup_rules

      tokens = rule_builder.instance_variable_get(:@replaced_rhs)

      expect(tokens.count).to eq 5
      expect(tokens[0].s_value).to eq 'keyword_class'
      expect(tokens[1].s_value).to eq '@1'
      expect(tokens[2].s_value).to eq 'tSTRING'
      expect(tokens[3].s_value).to eq '$@2'
      expect(tokens[4].s_value).to eq 'keyword_end'
    end
  end
end
