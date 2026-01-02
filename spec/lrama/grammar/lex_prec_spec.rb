# frozen_string_literal: true

RSpec.describe Lrama::Grammar::LexPrec do
  let(:lex_prec) { Lrama::Grammar::LexPrec.new }

  it "stores lex-prec rules" do
    left = Lrama::Lexer::Token::Ident.new(s_value: "RANGLE")
    right = Lrama::Lexer::Token::Ident.new(s_value: "RSHIFT")

    lex_prec.add_rule(
      left_token: left,
      operator: Lrama::Grammar::LexPrec::SHORTER,
      right_token: right,
      lineno: 1
    )

    expect(lex_prec.rules.size).to eq(1)
    expect(lex_prec.shorter_priority?("RANGLE", "RSHIFT")).to be true
    expect(lex_prec.shorter_priority?("RSHIFT", "RANGLE")).to be false
  end

  it "handles higher priority rules" do
    left = Lrama::Lexer::Token::Ident.new(s_value: "IF")
    right = Lrama::Lexer::Token::Ident.new(s_value: "ID")

    lex_prec.add_rule(
      left_token: left,
      operator: Lrama::Grammar::LexPrec::HIGHER,
      right_token: right,
      lineno: 1
    )

    expect(lex_prec.higher_priority?("IF", "ID")).to be true
    expect(lex_prec.higher_priority?("ID", "IF")).to be false
  end

  it "handles same priority (lex-tie) rules" do
    left = Lrama::Lexer::Token::Ident.new(s_value: "TOKEN_A")
    right = Lrama::Lexer::Token::Ident.new(s_value: "TOKEN_B")

    lex_prec.add_rule(
      left_token: left,
      operator: Lrama::Grammar::LexPrec::SAME_PRIORITY,
      right_token: right,
      lineno: 1
    )

    expect(lex_prec.same_priority?("TOKEN_A", "TOKEN_B")).to be true
    expect(lex_prec.same_priority?("TOKEN_B", "TOKEN_A")).to be true
  end
end
