# frozen_string_literal: true

RSpec.describe Lrama::LengthPrecedences do
  let(:lex_prec) { Lrama::Grammar::LexPrec.new }

  def ident(name)
    Lrama::Lexer::Token::Ident.new(s_value: name)
  end

  def add_rule(left, operator, right, lineno)
    lex_prec.add_rule(
      left_token: ident(left),
      operator: operator,
      right_token: ident(right),
      lineno: lineno
    )
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

  describe "#initialize" do
    it "rejects contradictory shortest and longest rules for the same scan direction" do
      add_rule("RANGLE", Lrama::Grammar::LexPrec::SHORTEST, "RSHIFT", 10)
      add_rule("RANGLE", Lrama::Grammar::LexPrec::LONGEST, "RSHIFT", 12)

      expect { Lrama::LengthPrecedences.new(lex_prec) }
        .to raise_error(
          Lrama::LengthPrecedences::LexicalPrecedenceConflictError,
          /RANGLE -> RSHIFT.*-s at line 10.*-~ at line 12/m
        )
    end

    it "rejects contradictory right-token length winners in reverse declarations" do
      add_rule("RANGLE", Lrama::Grammar::LexPrec::TOKEN_RIGHT_LENGTH, "RSHIFT", 20)
      add_rule("RSHIFT", Lrama::Grammar::LexPrec::TOKEN_RIGHT_LENGTH, "RANGLE", 21)

      expect { Lrama::LengthPrecedences.new(lex_prec) }
        .to raise_error(
          Lrama::LengthPrecedences::LexicalPrecedenceConflictError,
          /RSHIFT -> RANGLE.*-< at line 20.*-< at line 21/m
        )
    end

    it "allows repeated declarations with the same length resolution" do
      add_rule("RANGLE", Lrama::Grammar::LexPrec::LONGEST, "RSHIFT", 30)
      add_rule("RSHIFT", Lrama::Grammar::LexPrec::LONGEST, "RANGLE", 31)

      expect { Lrama::LengthPrecedences.new(lex_prec) }.not_to raise_error
    end
  end
end
