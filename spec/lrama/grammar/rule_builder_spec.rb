RSpec.describe Lrama::Grammar::RuleBuilder do
  let(:rule_builder) { Lrama::Grammar::RuleBuilder.new }

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
      rule_builder.freeze_rhs
      expect { rule_builder.add_rhs(token) }.to raise_error(FrozenError)
    end
  end
end
