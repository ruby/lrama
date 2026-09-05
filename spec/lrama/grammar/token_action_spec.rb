# frozen_string_literal: true

RSpec.describe Lrama::Grammar::TokenAction do
  def ident(name)
    Lrama::Lexer::Token::Ident.new(s_value: name)
  end

  def user_code(code)
    Lrama::Lexer::Token::UserCode.new(s_value: code)
  end

  it "stores token action attributes" do
    action = Lrama::Grammar::TokenAction.new(
      token_id: ident("ID"),
      code: user_code('printf("matched");'),
      lineno: 5
    )

    expect(action.token_name).to eq("ID")
    expect(action.code.s_value).to eq('printf("matched");')
    expect(action.lineno).to eq(5)
  end
end
