# frozen_string_literal: true

RSpec.describe Lrama::Pslr::PairwiseResolution do
  def token_pattern(name, regex, order)
    Lrama::Grammar::TokenPattern.new(
      id: Lrama::Lexer::Token::Ident.new(s_value: name),
      pattern: Lrama::Lexer::Token::Regex.new(s_value: "/#{regex}/"),
      lineno: 1,
      definition_order: order
    )
  end

  let(:rangle) { token_pattern("RANGLE", ">", 0) }
  let(:rshift) { token_pattern("RSHIFT", ">>", 1) }
  let(:identifier) { token_pattern("ID", "[a-z]+", 2) }
  let(:keyword) { token_pattern("IF", "if", 3) }
  let(:layout) { token_pattern("YYLAYOUT_WS", "[ ]+", 4) }
  let(:scanner_fsa) { Lrama::ScannerFSA.new([rangle, rshift, identifier, keyword, layout]) }
  let(:pairwise) { described_class.new(scanner_fsa) }

  it "treats identical accept sets as compatible" do
    acc = Set["RANGLE", "RSHIFT"]
    expect(pairwise.compatible_accept_sets?(acc, acc.dup)).to be true
  end

  it "splits states that pick different tokens of a conflict pair" do
    expect(pairwise.compatible_accept_sets?(Set["RANGLE"], Set["RSHIFT"])).to be false
  end

  it "splits a resolved state from a state seeing the full conflict" do
    expect(pairwise.compatible_accept_sets?(Set["ID"], Set["ID", "IF"])).to be false
  end

  it "treats states as compatible when one side has no match for the pair" do
    expect(pairwise.compatible_accept_sets?(Set["RANGLE"], Set["ID"])).to be true
  end

  it "ignores tokens without scanner conflicts" do
    expect(pairwise.compatible_accept_sets?(Set["RANGLE", "ID"], Set["RANGLE"])).to be true
  end

  it "never splits on layout tokens because they are in every accept set" do
    left = Set["RANGLE", "YYLAYOUT_WS"]
    right = Set["RANGLE", "RSHIFT", "YYLAYOUT_WS"]

    expect(pairwise.compatible_accept_sets?(left, right)).to be false
    expect(pairwise.compatible_accept_sets?(Set["ID", "YYLAYOUT_WS"], Set["YYLAYOUT_WS", "ID"])).to be true
  end
end
