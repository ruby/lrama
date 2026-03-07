# frozen_string_literal: true

RSpec.describe Lrama::ScannerFSA do
  describe "initialization" do
    it "creates an empty FSA for no patterns" do
      fsa = Lrama::ScannerFSA.new([])
      expect(fsa.states).to be_empty
    end

    it "creates FSA for single literal pattern" do
      id = Lrama::Lexer::Token::Ident.new(s_value: "PLUS")
      regex = Lrama::Lexer::Token::Regex.new(s_value: "/\\+/")
      token_pattern = Lrama::Grammar::TokenPattern.new(
        id: id,
        pattern: regex,
        lineno: 1,
        definition_order: 0
      )
      fsa = Lrama::ScannerFSA.new([token_pattern])

      expect(fsa.states).not_to be_empty
      expect(fsa.initial_state).not_to be_nil
    end
  end

  describe "#scan" do
    it "matches a single character pattern" do
      id = Lrama::Lexer::Token::Ident.new(s_value: "RANGLE")
      regex = Lrama::Lexer::Token::Regex.new(s_value: "/>/")
      token_pattern = Lrama::Grammar::TokenPattern.new(
        id: id,
        pattern: regex,
        lineno: 1,
        definition_order: 0
      )
      fsa = Lrama::ScannerFSA.new([token_pattern])

      results = fsa.scan(">")
      expect(results.size).to eq(1)
      expect(results[0][:token].name).to eq("RANGLE")
      expect(results[0][:position]).to eq(1)
    end

    it "matches a multi-character pattern" do
      id = Lrama::Lexer::Token::Ident.new(s_value: "RSHIFT")
      regex = Lrama::Lexer::Token::Regex.new(s_value: "/>>/")
      token_pattern = Lrama::Grammar::TokenPattern.new(
        id: id,
        pattern: regex,
        lineno: 1,
        definition_order: 0
      )
      fsa = Lrama::ScannerFSA.new([token_pattern])

      results = fsa.scan(">>")
      expect(results.size).to eq(1)
      expect(results[0][:token].name).to eq("RSHIFT")
      expect(results[0][:position]).to eq(2)
    end

    it "returns multiple matches for overlapping patterns" do
      rangle_id = Lrama::Lexer::Token::Ident.new(s_value: "RANGLE")
      rangle_regex = Lrama::Lexer::Token::Regex.new(s_value: "/>/")
      rangle = Lrama::Grammar::TokenPattern.new(
        id: rangle_id,
        pattern: rangle_regex,
        lineno: 1,
        definition_order: 0
      )

      rshift_id = Lrama::Lexer::Token::Ident.new(s_value: "RSHIFT")
      rshift_regex = Lrama::Lexer::Token::Regex.new(s_value: "/>>/")
      rshift = Lrama::Grammar::TokenPattern.new(
        id: rshift_id,
        pattern: rshift_regex,
        lineno: 1,
        definition_order: 1
      )

      fsa = Lrama::ScannerFSA.new([rangle, rshift])

      results = fsa.scan(">>")

      # Should match both RANGLE at position 1 and RSHIFT at position 2
      expect(results.size).to eq(2)
      positions = results.map { |r| [r[:token].name, r[:position]] }
      expect(positions).to include(["RANGLE", 1])
      expect(positions).to include(["RSHIFT", 2])
    end

    it "matches character class patterns" do
      id = Lrama::Lexer::Token::Ident.new(s_value: "ID")
      regex = Lrama::Lexer::Token::Regex.new(s_value: "/[a-zA-Z_][a-zA-Z0-9_]*/")
      id_pattern = Lrama::Grammar::TokenPattern.new(
        id: id,
        pattern: regex,
        lineno: 1,
        definition_order: 0
      )
      fsa = Lrama::ScannerFSA.new([id_pattern])

      results = fsa.scan("hello_world123")
      expect(results).not_to be_empty
      # Should have matches at each position as the identifier grows
    end

    it "matches digit patterns" do
      id = Lrama::Lexer::Token::Ident.new(s_value: "INT")
      regex = Lrama::Lexer::Token::Regex.new(s_value: "/[0-9]+/")
      int_pattern = Lrama::Grammar::TokenPattern.new(
        id: id,
        pattern: regex,
        lineno: 1,
        definition_order: 0
      )
      fsa = Lrama::ScannerFSA.new([int_pattern])

      results = fsa.scan("12345")
      expect(results).not_to be_empty
    end
  end

  describe "#acc_ss" do
    it "returns empty array for non-accepting state" do
      id = Lrama::Lexer::Token::Ident.new(s_value: "AB")
      regex = Lrama::Lexer::Token::Regex.new(s_value: "/ab/")
      token_pattern = Lrama::Grammar::TokenPattern.new(
        id: id,
        pattern: regex,
        lineno: 1,
        definition_order: 0
      )
      fsa = Lrama::ScannerFSA.new([token_pattern])

      # Initial state shouldn't be accepting for non-empty pattern
      tokens = fsa.acc_ss(0)
      expect(tokens).to be_empty
    end

    it "returns accepting tokens for accepting state" do
      id = Lrama::Lexer::Token::Ident.new(s_value: "A")
      regex = Lrama::Lexer::Token::Regex.new(s_value: "/a/")
      token_pattern = Lrama::Grammar::TokenPattern.new(
        id: id,
        pattern: regex,
        lineno: 1,
        definition_order: 0
      )
      fsa = Lrama::ScannerFSA.new([token_pattern])

      # Scan to reach accepting state
      results = fsa.scan("a")
      expect(results).not_to be_empty

      accepting_state = results[0][:state]
      tokens = fsa.acc_ss(accepting_state.id)
      expect(tokens.map(&:name)).to include("A")
    end
  end

  describe "#state_to_accepting_state" do
    it "returns nil for non-accepting state" do
      id = Lrama::Lexer::Token::Ident.new(s_value: "AB")
      regex = Lrama::Lexer::Token::Regex.new(s_value: "/ab/")
      token_pattern = Lrama::Grammar::TokenPattern.new(
        id: id,
        pattern: regex,
        lineno: 1,
        definition_order: 0
      )
      fsa = Lrama::ScannerFSA.new([token_pattern])

      expect(fsa.state_to_accepting_state(0)).to be_nil
    end

    it "returns the state itself for accepting state" do
      id = Lrama::Lexer::Token::Ident.new(s_value: "A")
      regex = Lrama::Lexer::Token::Regex.new(s_value: "/a/")
      token_pattern = Lrama::Grammar::TokenPattern.new(
        id: id,
        pattern: regex,
        lineno: 1,
        definition_order: 0
      )
      fsa = Lrama::ScannerFSA.new([token_pattern])

      results = fsa.scan("a")
      accepting_state = results[0][:state]

      expect(fsa.state_to_accepting_state(accepting_state.id)).to eq(accepting_state)
    end
  end
end
