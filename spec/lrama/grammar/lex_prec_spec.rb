# frozen_string_literal: true

RSpec.describe Lrama::Grammar::LexPrec do
  let(:lex_prec) { Lrama::Grammar::LexPrec.new }

  def ident(name)
    Lrama::Lexer::Token::Ident.new(s_value: name)
  end

  it "stores identity-right and longest-match rules" do
    lex_prec.add_rule(
      left_token: ident("ID"),
      operator: Lrama::Grammar::LexPrec::IDENTITY_RIGHT_LONGEST,
      right_token: ident("IF"),
      lineno: 1
    )

    expect(lex_prec.rules.size).to eq(1)
    expect(lex_prec.identity_precedes?("IF", "ID")).to be true
    expect(lex_prec.identity_precedes?("ID", "IF")).to be false
    expect(lex_prec.longest_pair?("ID", "IF")).to be true
  end

  it "does not infer transitive identity precedence" do
    lex_prec.add_rule(
      left_token: ident("A"),
      operator: Lrama::Grammar::LexPrec::IDENTITY_RIGHT,
      right_token: ident("B"),
      lineno: 1
    )
    lex_prec.add_rule(
      left_token: ident("B"),
      operator: Lrama::Grammar::LexPrec::IDENTITY_RIGHT,
      right_token: ident("C"),
      lineno: 1
    )

    expect(lex_prec.identity_precedes?("B", "A")).to be true
    expect(lex_prec.identity_precedes?("C", "B")).to be true
    expect(lex_prec.identity_precedes?("C", "A")).to be false
  end

  it "separates lexical ties from precedence" do
    tie = Lrama::Grammar::LexTie.new
    tie.add_tie("ID", "IF")

    expect(tie.tied?("ID", "IF")).to be true
    expect(lex_prec.identity_precedes?("IF", "ID")).to be false
  end
end
