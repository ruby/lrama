# frozen_string_literal: true

RSpec.describe Lrama::LengthPrecedences do
  let(:lex_prec) { Lrama::Grammar::LexPrec.new }

  def ident(name)
    Lrama::Lexer::Token::Ident.new(s_value: name)
  end

  describe "#resolution" do
    it "defaults same-token autolength conflicts to longest match" do
      length_prec = Lrama::LengthPrecedences.new(lex_prec)

      expect(length_prec.resolution("ID", "ID")).to eq(Lrama::LengthPrecedences::PREFER_NEW)
      expect(length_prec.precedes?("ID", "ID")).to be true
    end

    it "leaves different-token length conflicts unresolved without a rule" do
      length_prec = Lrama::LengthPrecedences.new(lex_prec)

      expect(length_prec.resolution("A", "B")).to eq(Lrama::LengthPrecedences::UNRESOLVED)
      expect(length_prec.precedence("A", "B")).to eq(:undefined)
    end

    it "supports explicit shortest-match precedence" do
      lex_prec.add_rule(
        left_token: ident("COM"),
        operator: Lrama::Grammar::LexPrec::SHORTEST,
        right_token: ident("COM"),
        lineno: 1
      )
      length_prec = Lrama::LengthPrecedences.new(lex_prec)

      expect(length_prec.resolution("COM", "COM")).to eq(Lrama::LengthPrecedences::PREFER_OLD)
      expect(length_prec.prefer_shorter?("COM", "COM")).to be true
    end

    it "supports explicit longest-match precedence" do
      lex_prec.add_rule(
        left_token: ident("ID"),
        operator: Lrama::Grammar::LexPrec::LONGEST,
        right_token: ident("IF"),
        lineno: 1
      )
      length_prec = Lrama::LengthPrecedences.new(lex_prec)

      expect(length_prec.resolution("ID", "IF")).to eq(Lrama::LengthPrecedences::PREFER_NEW)
      expect(length_prec.resolution("IF", "ID")).to eq(Lrama::LengthPrecedences::PREFER_NEW)
    end

    it "supports right-token length precedence" do
      lex_prec.add_rule(
        left_token: ident("WORD"),
        operator: Lrama::Grammar::LexPrec::TOKEN_RIGHT_LENGTH,
        right_token: ident("NON"),
        lineno: 1
      )
      length_prec = Lrama::LengthPrecedences.new(lex_prec)

      expect(length_prec.resolution("WORD", "NON")).to eq(Lrama::LengthPrecedences::PREFER_NEW)
      expect(length_prec.resolution("NON", "WORD")).to eq(Lrama::LengthPrecedences::PREFER_OLD)
    end
  end
end
