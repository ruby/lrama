RSpec.describe Lrama::Grammar::RuleBuilder do
  let(:rule_counter) { Lrama::Grammar::Counter.new(1) }
  let(:midrule_action_counter) { Lrama::Grammar::Counter.new(1) }
  let(:rule_builder) { Lrama::Grammar::RuleBuilder.new(rule_counter, midrule_action_counter) }
  let(:path) { "parse.y" }

  describe "#add_rhs" do
    describe "@line" do
      let(:location) { Lrama::Lexer::Location.new(grammar_file: Lrama::Lexer::GrammarFile.new(path, ""), first_line: 1, first_column: 0, last_line: 1, last_column: 4) }
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
      let(:location) { Lrama::Lexer::Location.new(grammar_file: Lrama::Lexer::GrammarFile.new(path, ""), first_line: 1, first_column: 0, last_line: 1, last_column: 4) }
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
      let(:location) { Lrama::Lexer::Location.new(grammar_file: Lrama::Lexer::GrammarFile.new(path, ""), first_line: 1, first_column: 0, last_line: 1, last_column: 4) }
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
      let(:location) { Lrama::Lexer::Location.new(grammar_file: Lrama::Lexer::GrammarFile.new(path, ""), first_line: 1, first_column: 0, last_line: 1, last_column: 4) }
      let(:token_1) { Lrama::Lexer::Token::UserCode.new(s_value: "code 1", location: location) }
      let(:sym) { Lrama::Grammar::Symbol.new(id: Lrama::Lexer::Token::Ident.new(s_value: "tPLUS"), term: true) }

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
    let(:location) { Lrama::Lexer::Location.new(grammar_file: Lrama::Lexer::GrammarFile.new(path, ""), first_line: 1, first_column: 0, last_line: 1, last_column: 4) }
    let(:token) { Lrama::Lexer::Token::Ident.new(s_value: "class", location: location) }

    it "can not add rhs after #freeze_rhs is called" do
      rule_builder.add_rhs(token)
      rule_builder.send(:freeze_rhs)
      expect { rule_builder.add_rhs(token) }.to raise_error(FrozenError)
    end
  end

  describe "#preprocess_references" do
    context "variables refer to correct name and correct position" do
      let(:location) { Lrama::Lexer::Location.new(grammar_file: Lrama::Lexer::GrammarFile.new(path, ""), first_line: 1, first_column: 0, last_line: 1, last_column: 4) }
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
      let(:location) { Lrama::Lexer::Location.new(grammar_file: Lrama::Lexer::GrammarFile.new(path, ""), first_line: 1, first_column: 0, last_line: 1, last_column: 4) }
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
      let(:text) { "class : keyword_class tSTRING keyword_end { $class = $10; }" }
      let(:grammar_file) { Lrama::Lexer::GrammarFile.new(path, text) }
      let(:location_1) { Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 0, last_line: 1, last_column: 5) }
      let(:location_2) { Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 8, last_line: 1, last_column: 21) }
      let(:location_3) { Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 22, last_line: 1, last_column: 29) }
      let(:location_4) { Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 30, last_line: 1, last_column: 41) }
      let(:location_5) { Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 43, last_line: 1, last_column: 58) }

      let(:token_1) { Lrama::Lexer::Token::Ident.new(s_value: "class", location: location_1) }
      let(:token_2) { Lrama::Lexer::Token::Ident.new(s_value: "keyword_class", location: location_2) }
      let(:token_3) { Lrama::Lexer::Token::Ident.new(s_value: "tSTRING", location: location_3) }
      let(:token_4) { Lrama::Lexer::Token::Ident.new(s_value: "keyword_end", location: location_4) }
      let(:token_5) { Lrama::Lexer::Token::UserCode.new(s_value: " $class = $10; ", location: location_5) }

      it "raises error" do
        rule_builder.lhs = token_1
        rule_builder.add_rhs(token_2)
        rule_builder.add_rhs(token_3)
        rule_builder.add_rhs(token_4)
        rule_builder.user_code = token_5
        rule_builder.complete_input

        expected = <<-TEXT
parse.y:1:53: Can not refer following component. 10 >= 4.
class : keyword_class tSTRING keyword_end { $class = $10; }
                                                     ^^^
        TEXT

        expect { rule_builder.send(:preprocess_references) }.to raise_error(expected)
      end
    end

    context "variables in mid action rule refer to following component" do
      let(:text) { "class : keyword_class { $3; } tSTRING keyword_end { $class = $1; }" }
      let(:grammar_file) { Lrama::Lexer::GrammarFile.new(path, text) }
      let(:location_1) { Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 0, last_line: 1, last_column: 5) }
      let(:location_2) { Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 8, last_line: 1, last_column: 21) }
      let(:location_3) { Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 23, last_line: 1, last_column: 28) }
      let(:location_4) { Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 30, last_line: 1, last_column: 37) }
      let(:location_5) { Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 38, last_line: 1, last_column: 49) }
      let(:location_6) { Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 51, last_line: 1, last_column: 65) }
      let(:token_1) { Lrama::Lexer::Token::Ident.new(s_value: "class", location: location_1) }
      let(:token_2) { Lrama::Lexer::Token::Ident.new(s_value: "keyword_class", location: location_2) }
      let(:token_3) { Lrama::Lexer::Token::UserCode.new(s_value: " $3; ", location: location_3) }
      let(:token_4) { Lrama::Lexer::Token::Ident.new(s_value: "tSTRING", location: location_4) }
      let(:token_5) { Lrama::Lexer::Token::Ident.new(s_value: "keyword_end", location: location_5) }
      let(:token_6) { Lrama::Lexer::Token::UserCode.new(s_value: " $class = $1; ", location: location_6) }

      it "raises error" do
        rule_builder.lhs = token_1
        rule_builder.add_rhs(token_2)
        rule_builder.user_code = token_3
        rule_builder.add_rhs(token_4)
        rule_builder.add_rhs(token_5)
        rule_builder.user_code = token_6
        rule_builder.complete_input

        expected = <<-TEXT
parse.y:1:24: Can not refer following component. 3 >= 2.
class : keyword_class { $3; } tSTRING keyword_end { $class = $1; }
                        ^^
        TEXT

        expect { rule_builder.send(:preprocess_references) }.to raise_error(expected)
      end
    end

    context "variables refer with wrong name" do
      let(:text) { "class : keyword_class tSTRING keyword_end { $classes = $1; }" }
      let(:grammar_file) { Lrama::Lexer::GrammarFile.new(path, text) }
      let(:location_1) { Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 0, last_line: 1, last_column: 5) }
      let(:location_2) { Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 8, last_line: 1, last_column: 21) }
      let(:location_3) { Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 22, last_line: 1, last_column: 29) }
      let(:location_4) { Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 30, last_line: 1, last_column: 41) }
      let(:location_5) { Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 43, last_line: 1, last_column: 59) }
      let(:token_1) { Lrama::Lexer::Token::Ident.new(s_value: "class", location: location_1) }
      let(:token_2) { Lrama::Lexer::Token::Ident.new(s_value: "keyword_class", location: location_2) }
      let(:token_3) { Lrama::Lexer::Token::Ident.new(s_value: "tSTRING", location: location_3) }
      let(:token_4) { Lrama::Lexer::Token::Ident.new(s_value: "keyword_end", location: location_4) }
      let(:token_5) { Lrama::Lexer::Token::UserCode.new(s_value: " $classes = $1; ", location: location_5) }

      it "raises error" do
        rule_builder.lhs = token_1
        rule_builder.add_rhs(token_2)
        rule_builder.add_rhs(token_3)
        rule_builder.add_rhs(token_4)
        rule_builder.user_code = token_5
        rule_builder.complete_input

        expected = <<-TEXT
parse.y:1:44: Referring symbol `classes` is not found.
class : keyword_class tSTRING keyword_end { $classes = $1; }
                                            ^^^^^^^^
        TEXT

        expect { rule_builder.send(:preprocess_references) }.to raise_error(expected)
      end
    end

    context "component name is duplicated" do
      context "components in RHS are duplicated" do
        let(:y) do
          <<-GRAMMAR
%token keyword_class
%token tSTRING
%token keyword_end

%%

program: class
       ;

class: keyword_class tSTRING tSTRING keyword_end { $class = $tSTRING; }
     ;

          GRAMMAR
        end

        it "raises error" do
          expected = <<-TEXT
parse.y:10:60: Referring symbol `tSTRING` is duplicated.
class: keyword_class tSTRING tSTRING keyword_end { $class = $tSTRING; }
                                                            ^^^^^^^^
          TEXT
          expect { Lrama::Parser.new(y, "parse.y").parse }.to raise_error(expected)
        end
      end

      context "components in LHS and RHS are duplicated" do
        let(:y) do
          <<-GRAMMAR
%token keyword_class
%token tSTRING
%token keyword_end

%%

program: class
       ;

class: class tSTRING keyword_end { $class = $tSTRING; }
     ;

          GRAMMAR
        end

        it "raises error" do
          expected = <<-TEXT
parse.y:10:35: Referring symbol `class` is duplicated.
class: class tSTRING keyword_end { $class = $tSTRING; }
                                   ^^^^^^
          TEXT
          expect { Lrama::Parser.new(y, "parse.y").parse }.to raise_error(expected)
        end
      end

      context "components in LHS and RHS are duplicated by alias name" do
        let(:y) do
          <<-GRAMMAR
%token keyword_class
%token tSTRING
%token keyword_end

%%

program: klass
       ;

klass[class]: class tSTRING keyword_end { $class = $tSTRING; }
            ;

          GRAMMAR
        end

        it "raises error" do
          expected = <<-TEXT
parse.y:10:42: Referring symbol `class` is duplicated.
klass[class]: class tSTRING keyword_end { $class = $tSTRING; }
                                          ^^^^^^
          TEXT
          expect { Lrama::Parser.new(y, "parse.y").parse }.to raise_error(expected)
        end
      end

      context "components in LHS and RHS are duplicated by alias name" do
        let(:y) do
          <<-GRAMMAR
%token keyword_class
%token tSTRING
%token keyword_end

%%

program: klass
       ;

klass[class]: Klass[class] tSTRING keyword_end { $class = $tSTRING; }
            ;

          GRAMMAR
        end

        it "raises error" do
          expected = <<-TEXT
parse.y:10:49: Referring symbol `class` is duplicated.
klass[class]: Klass[class] tSTRING keyword_end { $class = $tSTRING; }
                                                 ^^^^^^
          TEXT
          expect { Lrama::Parser.new(y, "parse.y").parse }.to raise_error(expected)
        end
      end
    end
  end

  describe "#midrule_action_rules" do
    let(:location) { Lrama::Lexer::Location.new(grammar_file: Lrama::Lexer::GrammarFile.new(path, ""), first_line: 1, first_column: 0, last_line: 1, last_column: 4) }
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
      rule_builder.setup_rules(Lrama::Grammar::ParameterizingRule::Resolver.new)

      rules = rule_builder.rules
      midrule_1 = rules.find {|rule| rule._lhs.s_value == "@1"}
      midrule_2 = rules.find {|rule| rule._lhs.s_value == "$@2"}
      rule = rules.find {|rule| rule._lhs.s_value == "class"}

      expect(rules.count).to eq 3
      expect(midrule_1._lhs.s_value).to eq '@1'
      expect(midrule_1.token_code.s_value).to eq '$1'
      expect(midrule_1.original_rule).to eq rule
      expect(midrule_2._lhs.s_value).to eq '$@2'
      expect(midrule_2.token_code.s_value).to eq '$2 + $3'
      expect(midrule_2.original_rule).to eq rule
    end
  end

  describe "@replaced_rhs" do
    let(:location) { Lrama::Lexer::Location.new(grammar_file: Lrama::Lexer::GrammarFile.new(path, ""), first_line: 1, first_column: 0, last_line: 1, last_column: 4) }
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
      rule_builder.setup_rules(Lrama::Grammar::ParameterizingRule::Resolver.new)

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
