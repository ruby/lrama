# frozen_string_literal: true

RSpec.describe Lrama::Grammar::TokenPattern do
  it "stores token pattern information" do
    id = Lrama::Lexer::Token::Ident.new(s_value: "RSHIFT")
    pattern = Lrama::Lexer::Token::Regex.new(s_value: "/>>>/")

    token_pattern = Lrama::Grammar::TokenPattern.new(
      id: id,
      pattern: pattern,
      alias_name: "right shift",
      tag: nil,
      lineno: 1,
      definition_order: 0
    )

    expect(token_pattern.name).to eq("RSHIFT")
    expect(token_pattern.regex_pattern).to eq(">>>")
    expect(token_pattern.alias_name).to eq("right shift")
    expect(token_pattern.definition_order).to eq(0)
  end

  it "recognizes YYLAYOUT-prefixed layout tokens" do
    pattern = Lrama::Lexer::Token::Regex.new(s_value: "/[ ]+/")
    layout = Lrama::Grammar::TokenPattern.new(
      id: Lrama::Lexer::Token::Ident.new(s_value: "YYLAYOUT_COMMENT"),
      pattern: pattern,
      lineno: 1,
      definition_order: 0
    )
    normal = Lrama::Grammar::TokenPattern.new(
      id: Lrama::Lexer::Token::Ident.new(s_value: "ID"),
      pattern: pattern,
      lineno: 1,
      definition_order: 1
    )

    expect(layout).to be_layout
    expect(normal).not_to be_layout
  end
end
