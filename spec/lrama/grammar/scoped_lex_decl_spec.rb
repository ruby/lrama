# frozen_string_literal: true

RSpec.describe Lrama::Grammar::ScopedLexDecl do
  def ident(name)
    Lrama::Lexer::Token::Ident.new(s_value: name)
  end

  it "stores scope name and lex-prec rules" do
    decl = Lrama::Grammar::ScopedLexDecl.new(scope_name: "template_args", lineno: 10)

    rule = Lrama::Grammar::LexPrec::Rule.new(
      left_token: ident("RANGLE"),
      operator: Lrama::Grammar::LexPrec::LONGEST,
      right_token: ident("RSHIFT"),
      lineno: 11
    )
    decl.add_lex_prec_rule(rule)

    expect(decl.scope_name).to eq("template_args")
    expect(decl.lex_prec_rules.size).to eq(1)
    expect(decl.lex_prec_rules.first.left_name).to eq("RANGLE")
    expect(decl.lex_prec_rules.first.right_name).to eq("RSHIFT")
  end

  it "stores lex-tie declarations" do
    decl = Lrama::Grammar::ScopedLexDecl.new(scope_name: "expr", lineno: 1)

    tie = Lrama::Grammar::LexTie::Declaration.new(
      kind: :tie,
      groups: [
        Lrama::Grammar::LexTie::OperandGroup.new(names: ["ID"], kind: :token),
        Lrama::Grammar::LexTie::OperandGroup.new(names: ["KW_IF"], kind: :token)
      ],
      lineno: 2
    )
    decl.add_lex_tie_declaration(tie)

    expect(decl.lex_tie_declarations.size).to eq(1)
  end
end
