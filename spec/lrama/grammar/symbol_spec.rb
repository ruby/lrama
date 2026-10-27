# frozen_string_literal: true

RSpec.describe Lrama::Grammar::Symbol do
  describe Lrama::Grammar::Symbol::Id do
    describe ".from_token" do
      it "raises an error for a token that cannot identify a symbol" do
        token = Lrama::Lexer::Token::Token.new(s_value: "+")

        expect { described_class.from_token(token) }
          .to raise_error("Unexpected symbol token: Lrama::Lexer::Token::Token")
      end
    end

    describe "#==" do
      it "compares name and kind" do
        expect(symbol_id("term")).to eq(symbol_id("term"))
        expect(symbol_id("term")).not_to eq(symbol_id("term", kind: :char))
        expect(symbol_id("term")).not_to eq(symbol_id("other"))
      end
    end
  end

  describe "#enum_name" do
    describe "symbol is accept_symbol" do
      it "returns 'YYSYMBOL_YYACCEPT'" do
        sym = described_class.new(id: symbol_id("$accept"), term: false)
        sym.accept_symbol = true

        expect(sym.enum_name).to eq("YYSYMBOL_YYACCEPT")
      end
    end

    describe "symbol is eof_symbol" do
      it "returns 'YYSYMBOL_YYEOF'" do
        sym = described_class.new(id: symbol_id("YYEOF"), alias_name: "\"end of file\"", token_id: 0, term: true)
        sym.number = 0
        sym.eof_symbol = true

        expect(sym.enum_name).to eq("YYSYMBOL_YYEOF")
      end
    end

    describe "symbol's token_id is less than 128" do
      it "returns 'YYSYMBOL_number_[alias_name_]'" do
        sym1 = described_class.new(id: symbol_id("'\\\\'", kind: :char), alias_name: "\"backslash\"", token_id: 92, number: 70, term: true)
        sym2 = described_class.new(id: symbol_id("'.'", kind: :char), alias_name: nil, token_id: 46, number: 69, term: true)
        sym3 = described_class.new(id: symbol_id("'\\n'", kind: :char), alias_name: nil, token_id: 10, number: 162, term: true)

        expect(sym1.enum_name).to eq("YYSYMBOL_70_backslash_")
        expect(sym2.enum_name).to eq("YYSYMBOL_69_")
        expect(sym3.enum_name).to eq("YYSYMBOL_162_n_")
      end
    end

    describe "symbol includes $ or @" do
      it "returns 'YYSYMBOL_number_ref" do
        sym1 = described_class.new(id: symbol_id("$@1"), token_id: -1, number: 165, term: false)
        sym2 = described_class.new(id: symbol_id("@2"), token_id: -1, number: 166, term: false)

        expect(sym1.enum_name).to eq("YYSYMBOL_165_1")
        expect(sym2.enum_name).to eq("YYSYMBOL_166_2")
      end
    end

    describe "symbol's token_id is greater than 127" do
      it "returns 'YYSYMBOL_number_ref" do
        sym1 = described_class.new(id: symbol_id("keyword_class"), alias_name: "\"`class'\"", token_id: 258, number: 3, term: true)
        sym2 = described_class.new(id: symbol_id("top_compstmt"), token_id: 166, number: -1, term: false)

        expect(sym1.enum_name).to eq("YYSYMBOL_keyword_class")
        expect(sym2.enum_name).to eq("YYSYMBOL_top_compstmt")
      end
    end
  end

  describe "#comment" do
    describe "symbol is accept_symbol" do
      it "returns name" do
        sym = described_class.new(id: symbol_id("$accept"), term: false)
        sym.accept_symbol = true

        expect(sym.comment).to eq("$accept")
      end
    end

    describe "symbol is eof_symbol" do
      it "returns alias_name" do
        sym = described_class.new(id: symbol_id("YYEOF"), alias_name: "\"end of file\"", token_id: 0, term: true)
        sym.number = 0
        sym.eof_symbol = true

        expect(sym.comment).to eq("\"end of file\"")
      end
    end

    describe "symbol's token_id is less than 128" do
      it "returns alias_name or name" do
        sym1 = described_class.new(id: symbol_id("'\\\\'", kind: :char), alias_name: "\"backslash\"", token_id: 92, number: 70, term: true)
        sym2 = described_class.new(id: symbol_id("'.'", kind: :char), alias_name: nil, token_id: 46, number: 69, term: true)
        sym3 = described_class.new(id: symbol_id("'\\n'", kind: :char), alias_name: nil, token_id: 10, number: 162, term: true)

        expect(sym1.comment).to eq("\"backslash\"")
        expect(sym2.comment).to eq("'.'")
        expect(sym3.comment).to eq("'\\n'")
      end
    end

    describe "symbol includes $ or @" do
      it "returns name" do
        sym1 = described_class.new(id: symbol_id("$@1"), token_id: -1, number: 165, term: false)
        sym2 = described_class.new(id: symbol_id("@2"), token_id: -1, number: 166, term: false)

        expect(sym1.comment).to eq("$@1")
        expect(sym2.comment).to eq("@2")
      end
    end

    describe "symbol's token_id is greater than 127" do
      it "returns alias_name or name" do
        sym1 = described_class.new(id: symbol_id("keyword_class"), alias_name: "\"`class'\"", token_id: 258, number: 3, term: true)
        sym2 = described_class.new(id: symbol_id("top_compstmt"), token_id: 166, number: -1, term: false)

        expect(sym1.comment).to eq("\"`class'\"")
        expect(sym2.comment).to eq("top_compstmt")
      end
    end
  end
end
