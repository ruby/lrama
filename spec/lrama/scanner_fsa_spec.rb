# frozen_string_literal: true

RSpec.describe Lrama::ScannerFSA do
  def token_pattern(name, regex, lineno: 1, order: 0)
    Lrama::Grammar::TokenPattern.new(
      id: Lrama::Lexer::Token::Ident.new(s_value: name),
      pattern: Lrama::Lexer::Token::Regex.new(s_value: "/#{regex}/"),
      lineno: lineno,
      definition_order: order
    )
  end

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

    it "matches escaped whitespace inside character classes" do
      id = Lrama::Lexer::Token::Ident.new(s_value: "YYLAYOUT")
      regex = Lrama::Lexer::Token::Regex.new(s_value: "/[ \\t\\r\\n]+/")
      token_pattern = Lrama::Grammar::TokenPattern.new(
        id: id,
        pattern: regex,
        lineno: 1,
        definition_order: 0
      )
      fsa = Lrama::ScannerFSA.new([token_pattern])

      expect(fsa.scan("\t").map { |result| result[:token].name }).to include("YYLAYOUT")
      expect(fsa.scan("\n").map { |result| result[:token].name }).to include("YYLAYOUT")
    end

    it "matches escaped literals in and outside character classes" do
      slash = token_pattern("SLASH", "\\/", order: 0)
      rbrack = token_pattern("RBRACK", "[\\]]", order: 1)
      backslash = token_pattern("BACKSLASH", "[\\\\]", order: 2)

      expect(Lrama::ScannerFSA.new([slash]).scan("/").map { |result| result[:token].name }).to include("SLASH")
      expect(Lrama::ScannerFSA.new([rbrack]).scan("]").map { |result| result[:token].name }).to include("RBRACK")
      expect(Lrama::ScannerFSA.new([backslash]).scan("\\").map { |result| result[:token].name }).to include("BACKSLASH")
    end

    it "matches ranges and negated character classes over ASCII" do
      not_star = token_pattern("NOT_STAR", "[^*]+")
      fsa = Lrama::ScannerFSA.new([not_star])

      expect(fsa.scan("abc/]").map { |result| result[:token].name }).to include("NOT_STAR")
      expect(fsa.scan("a\nb").map { |result| result[:token].name }).to include("NOT_STAR")
      expect(fsa.scan("*")).to be_empty
    end
  end

  describe "pattern validation" do
    it "rejects empty token patterns" do
      expect { Lrama::ScannerFSA.new([token_pattern("EMPTY", "", lineno: 42)]) }
        .to raise_error(Lrama::ScannerFSA::PatternError, /EMPTY at line 42.*empty patterns/m)
    end

    it "rejects dangling escapes" do
      expect { Lrama::ScannerFSA.new([token_pattern("BAD_ESCAPE", "abc\\", lineno: 7)]) }
        .to raise_error(Lrama::ScannerFSA::PatternError, /BAD_ESCAPE at line 7.*dangling escape/m)
    end

    it "rejects unclosed character classes" do
      expect { Lrama::ScannerFSA.new([token_pattern("BAD_CLASS", "[abc", lineno: 6)]) }
        .to raise_error(Lrama::ScannerFSA::PatternError, /BAD_CLASS at line 6.*unclosed character class/m)
    end

    it "rejects unsupported alphabetic escapes" do
      expect { Lrama::ScannerFSA.new([token_pattern("BAD_ESCAPE", "\\q", lineno: 8)]) }
        .to raise_error(Lrama::ScannerFSA::PatternError, /BAD_ESCAPE at line 8.*unsupported escape \\q/m)
    end

    it "rejects malformed character class ranges" do
      expect { Lrama::ScannerFSA.new([token_pattern("BAD_RANGE", "[z-a]", lineno: 9)]) }
        .to raise_error(Lrama::ScannerFSA::PatternError, /BAD_RANGE at line 9.*invalid character class range z-a/m)
    end

    it "rejects nullable token patterns" do
      expect { Lrama::ScannerFSA.new([token_pattern("NULLABLE", "a*", lineno: 10)]) }
        .to raise_error(Lrama::ScannerFSA::PatternError, /NULLABLE at line 10.*nullable patterns/m)
      expect { Lrama::ScannerFSA.new([token_pattern("NULLABLE", "a?", lineno: 10)]) }
        .to raise_error(Lrama::ScannerFSA::PatternError, /NULLABLE at line 10.*nullable patterns/m)
      expect { Lrama::ScannerFSA.new([token_pattern("NULLABLE", "()", lineno: 10)]) }
        .to raise_error(Lrama::ScannerFSA::PatternError, /NULLABLE at line 10.*empty groups/m)
    end

    it "rejects empty alternatives" do
      expect { Lrama::ScannerFSA.new([token_pattern("EMPTY_ALT", "a|", lineno: 11)]) }
        .to raise_error(Lrama::ScannerFSA::PatternError, /EMPTY_ALT at line 11.*empty alternatives/m)
    end
  end

  describe "#pairwise_conflict_pairs" do
    it "detects identity and length conflicts" do
      rangle = Lrama::Grammar::TokenPattern.new(
        id: Lrama::Lexer::Token::Ident.new(s_value: "RANGLE"),
        pattern: Lrama::Lexer::Token::Regex.new(s_value: "/>/"),
        lineno: 1,
        definition_order: 0
      )
      rshift = Lrama::Grammar::TokenPattern.new(
        id: Lrama::Lexer::Token::Ident.new(s_value: "RSHIFT"),
        pattern: Lrama::Lexer::Token::Regex.new(s_value: "/>>/"),
        lineno: 1,
        definition_order: 1
      )
      keyword = Lrama::Grammar::TokenPattern.new(
        id: Lrama::Lexer::Token::Ident.new(s_value: "IF"),
        pattern: Lrama::Lexer::Token::Regex.new(s_value: "/if/"),
        lineno: 1,
        definition_order: 2
      )
      identifier = Lrama::Grammar::TokenPattern.new(
        id: Lrama::Lexer::Token::Ident.new(s_value: "ID"),
        pattern: Lrama::Lexer::Token::Regex.new(s_value: "/[a-z]+/"),
        lineno: 1,
        definition_order: 3
      )

      pairs = Lrama::ScannerFSA.new([rangle, rshift, keyword, identifier]).pairwise_conflict_pairs

      expect(pairs).to include(["RANGLE", "RSHIFT"])
      expect(pairs).to include(["ID", "IF"])
    end

    it "checks pairwise conflicts for sorted token pairs" do
      rangle = token_pattern("RANGLE", ">", order: 0)
      rshift = token_pattern("RSHIFT", ">>", order: 1)
      dot = token_pattern("DOT", "\\.", order: 2)
      comma = token_pattern("COMMA", ",", order: 3)
      fsa = Lrama::ScannerFSA.new([rangle, rshift, dot, comma])

      expect(fsa.pairwise_conflict?("RSHIFT", "RANGLE")).to be true
      expect(fsa.pairwise_conflict?("DOT", "COMMA")).to be false
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
