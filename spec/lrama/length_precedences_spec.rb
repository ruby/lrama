# frozen_string_literal: true

RSpec.describe Lrama::LengthPrecedences do
  let(:lex_prec) { Lrama::Grammar::LexPrec.new }

  describe "#precedence" do
    it "returns :undefined when no rule exists" do
      length_prec = Lrama::LengthPrecedences.new(lex_prec)
      expect(length_prec.precedence("TOKEN_A", "TOKEN_B")).to eq(:undefined)
    end

    it "returns :left when shorter token should be preferred" do
      left_token = Lrama::Lexer::Token::Ident.new(s_value: "RANGLE")
      right_token = Lrama::Lexer::Token::Ident.new(s_value: "RSHIFT")
      lex_prec.add_rule(
        left_token: left_token,
        operator: Lrama::Grammar::LexPrec::SHORTER,
        right_token: right_token,
        lineno: 1
      )
      length_prec = Lrama::LengthPrecedences.new(lex_prec)

      expect(length_prec.precedence("RANGLE", "RSHIFT")).to eq(:left)
    end

    it "returns :right for the inverse relationship" do
      left_token = Lrama::Lexer::Token::Ident.new(s_value: "RANGLE")
      right_token = Lrama::Lexer::Token::Ident.new(s_value: "RSHIFT")
      lex_prec.add_rule(
        left_token: left_token,
        operator: Lrama::Grammar::LexPrec::SHORTER,
        right_token: right_token,
        lineno: 1
      )
      length_prec = Lrama::LengthPrecedences.new(lex_prec)

      expect(length_prec.precedence("RSHIFT", "RANGLE")).to eq(:right)
    end
  end

  describe "#prefer_shorter?" do
    it "returns true when shorter token should be preferred" do
      left_token = Lrama::Lexer::Token::Ident.new(s_value: "RANGLE")
      right_token = Lrama::Lexer::Token::Ident.new(s_value: "RSHIFT")
      lex_prec.add_rule(
        left_token: left_token,
        operator: Lrama::Grammar::LexPrec::SHORTER,
        right_token: right_token,
        lineno: 1
      )
      length_prec = Lrama::LengthPrecedences.new(lex_prec)

      expect(length_prec.prefer_shorter?("RANGLE", "RSHIFT")).to be true
    end

    it "returns false when no preference exists" do
      length_prec = Lrama::LengthPrecedences.new(lex_prec)

      expect(length_prec.prefer_shorter?("TOKEN_A", "TOKEN_B")).to be false
    end

    it "returns false for inverse relationship" do
      left_token = Lrama::Lexer::Token::Ident.new(s_value: "RANGLE")
      right_token = Lrama::Lexer::Token::Ident.new(s_value: "RSHIFT")
      lex_prec.add_rule(
        left_token: left_token,
        operator: Lrama::Grammar::LexPrec::SHORTER,
        right_token: right_token,
        lineno: 1
      )
      length_prec = Lrama::LengthPrecedences.new(lex_prec)

      expect(length_prec.prefer_shorter?("RSHIFT", "RANGLE")).to be false
    end
  end
end
