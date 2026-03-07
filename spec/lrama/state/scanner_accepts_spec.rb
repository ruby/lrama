# frozen_string_literal: true

RSpec.describe Lrama::State::ScannerAccepts do
  describe "#build and #[]" do
    let(:rangle) do
      id = Lrama::Lexer::Token::Ident.new(s_value: "RANGLE")
      regex = Lrama::Lexer::Token::Regex.new(s_value: "/>/")
      Lrama::Grammar::TokenPattern.new(
        id: id,
        pattern: regex,
        lineno: 1,
        definition_order: 0
      )
    end

    let(:rshift) do
      id = Lrama::Lexer::Token::Ident.new(s_value: "RSHIFT")
      regex = Lrama::Lexer::Token::Regex.new(s_value: "/>>/")
      Lrama::Grammar::TokenPattern.new(
        id: id,
        pattern: regex,
        lineno: 1,
        definition_order: 1
      )
    end

    let(:scanner_fsa) { Lrama::ScannerFSA.new([rangle, rshift]) }
    let(:lex_prec) { Lrama::Grammar::LexPrec.new }
    let(:length_prec) { Lrama::LengthPrecedences.new(lex_prec) }

    context "with mock parser states" do
      let(:mock_symbol) do
        instance_double(
          Lrama::Grammar::Symbol,
          term?: true,
          id: instance_double(Lrama::Lexer::Token::Ident, s_value: "RANGLE")
        )
      end

      let(:mock_shift) do
        instance_double(
          Lrama::State::Action::Shift,
          next_sym: mock_symbol
        )
      end

      let(:mock_state) do
        instance_double(
          Lrama::State,
          id: 0,
          term_transitions: [mock_shift],
          reduces: []
        )
      end

      it "builds scanner_accepts table" do
        scanner_accepts = Lrama::State::ScannerAccepts.new(
          [mock_state],
          scanner_fsa,
          lex_prec,
          length_prec
        )
        scanner_accepts.build

        expect(scanner_accepts.table).to be_a(Hash)
      end
    end
  end

  describe "token selection logic" do
    let(:token_a) do
      id = Lrama::Lexer::Token::Ident.new(s_value: "TOKEN_A")
      regex = Lrama::Lexer::Token::Regex.new(s_value: "/a/")
      Lrama::Grammar::TokenPattern.new(
        id: id,
        pattern: regex,
        lineno: 1,
        definition_order: 0
      )
    end

    let(:token_ab) do
      id = Lrama::Lexer::Token::Ident.new(s_value: "TOKEN_AB")
      regex = Lrama::Lexer::Token::Regex.new(s_value: "/ab/")
      Lrama::Grammar::TokenPattern.new(
        id: id,
        pattern: regex,
        lineno: 1,
        definition_order: 1
      )
    end

    let(:scanner_fsa) { Lrama::ScannerFSA.new([token_a, token_ab]) }
    let(:lex_prec) { Lrama::Grammar::LexPrec.new }
    let(:length_prec) { Lrama::LengthPrecedences.new(lex_prec) }

    it "creates FSA with accepting states" do
      expect(scanner_fsa.states).not_to be_empty
    end
  end

  describe "priority selection with lex-prec rules" do
    let(:if_token) do
      id = Lrama::Lexer::Token::Ident.new(s_value: "IF")
      regex = Lrama::Lexer::Token::Regex.new(s_value: "/if/")
      Lrama::Grammar::TokenPattern.new(
        id: id,
        pattern: regex,
        lineno: 1,
        definition_order: 0
      )
    end

    let(:id_token) do
      id = Lrama::Lexer::Token::Ident.new(s_value: "ID")
      regex = Lrama::Lexer::Token::Regex.new(s_value: "/[a-z]+/")
      Lrama::Grammar::TokenPattern.new(
        id: id,
        pattern: regex,
        lineno: 1,
        definition_order: 1
      )
    end

    let(:scanner_fsa) { Lrama::ScannerFSA.new([if_token, id_token]) }
    let(:lex_prec) { Lrama::Grammar::LexPrec.new }

    before do
      left = Lrama::Lexer::Token::Ident.new(s_value: "IF")
      right = Lrama::Lexer::Token::Ident.new(s_value: "ID")
      lex_prec.add_rule(
        left_token: left,
        operator: Lrama::Grammar::LexPrec::HIGHER,
        right_token: right,
        lineno: 1
      )
    end

    it "respects higher priority rules" do
      expect(lex_prec.higher_priority?("IF", "ID")).to be true
    end

    it "creates length precedences from lex_prec" do
      length_prec = Lrama::LengthPrecedences.new(lex_prec)
      expect(length_prec).to be_a(Lrama::LengthPrecedences)
    end
  end
end
