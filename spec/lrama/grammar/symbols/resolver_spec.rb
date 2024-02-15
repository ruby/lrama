RSpec.describe Lrama::Grammar::Symbols::Resolver do
  let(:resolver) { Lrama::Grammar::Symbols::Resolver.new }

  describe "#symbols" do
    it "returns all symbols" do
      resolver.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: "term"))
      resolver.add_nterm(id: Lrama::Lexer::Token::Ident.new(s_value: "nterm"), alias_name: "alias")
      expect(resolver.symbols).to eq([
        resolver.terms[0], resolver.nterms[0]
      ])
    end
  end

  describe "#sort_by_number!" do
    it "sorts symbols by number" do
      resolver.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: "term"))
      resolver.add_nterm(id: Lrama::Lexer::Token::Ident.new(s_value: "nterm"))
      resolver.terms[0].number = 1
      resolver.nterms[0].number = 2
      resolver.sort_by_number!
      expect(resolver.symbols).to eq([
        resolver.terms[0], resolver.nterms[0]
      ])
      resolver.terms[0].number = 2
      resolver.nterms[0].number = 1
      resolver.sort_by_number!
      expect(resolver.symbols).to eq([
        resolver.nterms[0], resolver.terms[0]
      ])
    end
  end

  describe "#add_term" do
    it "adds term" do
      term = resolver.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: "term"))
      expect(term).to be_a(Lrama::Grammar::Symbol)
      expect(resolver.terms).to eq([term])
    end

    it "adds term with alias_name and tag" do
      term = resolver.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: "term"), alias_name: "alias", tag: "tag")
      expect(term).to be_a(Lrama::Grammar::Symbol)
      expect(term.alias_name).to eq("alias")
      expect(term.tag).to eq("tag")
    end

    it "adds term with token_id" do
      term = resolver.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: "term"), token_id: 1)
      expect(term).to be_a(Lrama::Grammar::Symbol)
      expect(term.token_id).to eq(1)
    end

    it "returns existing term" do
      term1 = resolver.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: "term"))
      term2 = resolver.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: "term"))
      expect(term1).to eq(term2)
    end

    it "replaces existing term" do
      term1 = resolver.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: "term"))
      term2 = resolver.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: "term"), replace: true)
      expect(term1).to eq(term2)
    end
  end

  describe "#add_nterm" do
    it "adds nterm" do
      nterm = resolver.add_nterm(id: Lrama::Lexer::Token::Ident.new(s_value: "nterm"))
      expect(nterm).to be_a(Lrama::Grammar::Symbol)
      expect(resolver.nterms).to eq([nterm])
    end

    it "adds nterm with alias_name and tag" do
      nterm = resolver.add_nterm(id: Lrama::Lexer::Token::Ident.new(s_value: "nterm"), alias_name: "alias", tag: "tag")
      expect(nterm).to be_a(Lrama::Grammar::Symbol)
      expect(nterm.alias_name).to eq("alias")
      expect(nterm.tag).to eq("tag")
    end

    it "returns nil if nterm exists" do
      nterm1 = resolver.add_nterm(id: Lrama::Lexer::Token::Ident.new(s_value: "nterm"))
      nterm2 = resolver.add_nterm(id: Lrama::Lexer::Token::Ident.new(s_value: "nterm"))
      expect(nterm2).to eq(nil)
    end
  end

  describe "#find_symbol_by_s_value" do
    it "finds symbol by s_value" do
      term = resolver.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: "term"))
      expect(resolver.find_symbol_by_s_value("term")).to eq(term)
    end

    it "returns nil if symbol not found" do
      expect(resolver.find_symbol_by_s_value("term")).to eq(nil)
    end
  end

  describe "#find_symbol_by_s_value!" do
    it "finds symbol by s_value" do
      term = resolver.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: "term"))
      expect(resolver.find_symbol_by_s_value!("term")).to eq(term)
    end

    it "raises error if symbol not found" do
      expect { resolver.find_symbol_by_s_value!("term") }.to raise_error("Symbol not found. value: `term`")
    end
  end

  describe "#find_symbol_by_id" do
    it "finds symbol by id" do
      term = resolver.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: "term"))
      expect(resolver.find_symbol_by_id(term.id)).to eq(term)
    end

    it "finds symbol by alias_name" do
      term = resolver.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: "term"), alias_name: "alias")
      symbol = Lrama::Grammar::Symbol.new(id: Lrama::Lexer::Token::Ident.new(s_value: "alias"), alias_name: "alias", term: true)
      expect(resolver.find_symbol_by_id(symbol.id)).to eq(term)
    end

    it "returns nil if symbol not found" do
      expect(resolver.find_symbol_by_id("term")).to eq(nil)
    end
  end

  describe "#find_symbol_by_id!" do
    it "finds symbol by id" do
      term = resolver.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: "term"))
      expect(resolver.find_symbol_by_id!(term.id)).to eq(term)
    end

    it "raises error if symbol not found" do
      grammar_file = Lrama::Lexer::GrammarFile.new("foo/basic.y", "")
      location = Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 2, last_line: 3, last_column: 4)
      symbol = Lrama::Grammar::Symbol.new(id: Lrama::Lexer::Token::Ident.new(s_value: "alias", location: location), alias_name: "alias", term: true)
      expect { resolver.find_symbol_by_id!(symbol.id) }.to raise_error("Symbol not found. value: `alias`, location: foo/basic.y (1,2)-(3,4)")
    end
  end

  describe "#find_symbol_by_token_id" do
    it "finds symbol by token_id" do
      term = resolver.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: "term"), token_id: 1)
      expect(resolver.find_symbol_by_token_id(1)).to eq(term)
    end

    it "returns nil if symbol not found" do
      expect(resolver.find_symbol_by_token_id(1)).to eq(nil)
    end
  end

  describe "#find_symbol_by_number!" do
    it "finds symbol by number" do
      term = resolver.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: "term"))
      term.number = 0
      expect(resolver.find_symbol_by_number!(0)).to eq(term)
    end

    it "raises error if symbol not found" do
      expect { resolver.find_symbol_by_number!(0) }.to raise_error("Symbol not found. number: `0`")
    end
  end

  describe "#fill_symbol_number" do
    it "fills symbol number" do
      term = resolver.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: "term"))
      nterm = resolver.add_nterm(id: Lrama::Lexer::Token::Ident.new(s_value: "nterm"))
      resolver.fill_symbol_number
      expect(term.number).to eq(3)
      expect(nterm.number).to eq(4)
    end
  end

  describe "#fill_nterm_type" do
    it "fills nterm type" do
      nterm = resolver.add_nterm(id: Lrama::Lexer::Token::Ident.new(s_value: "nterm"))
      resolver.fill_nterm_type([
        Lrama::Grammar::Type.new(id: Lrama::Lexer::Token::Ident.new(s_value: "nterm"), tag: "tag")
      ])
      expect(nterm.tag).to eq("tag")
    end
  end

  describe "#fill_printer" do
    it "fills printer" do
      term = resolver.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: "term"))
      printer = Lrama::Grammar::Printer.new(
        ident_or_tags: [Lrama::Lexer::Token::Ident.new(s_value: "term")]
      )
      resolver.fill_printer([printer])
      expect(term.printer).to eq(printer)
    end
  end

  describe "#fill_error_token" do
    it "fills error token" do
      term = resolver.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: "term"))
      token = Lrama::Lexer::Token::Ident.new(s_value: "term")
      resolver.fill_error_token([Lrama::Grammar::ErrorToken.new(ident_or_tags: [token])])
      expect(term.error_token.ident_or_tags).to eq([token])
    end
  end

  describe "#token_to_symbol" do
    it "returns symbol" do
      term = resolver.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: "term"))
      expect(resolver.token_to_symbol(term.id)).to eq(term)
    end
  end

  describe "#validate!" do
    it "validates number uniqueness" do
      term = resolver.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: "term"))
      term2 = resolver.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: "term2"))
      term.number = 1
      term2.number = 1
      expect { resolver.validate! }.to raise_error(/Symbol number is duplicated./)
    end

    it "validates alias_name uniqueness" do
      term = resolver.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: "term"), alias_name: "alias")
      term2 = resolver.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: "term2"), alias_name: "alias")
      term.number = 1
      term2.number = 2
      expect { resolver.validate! }.to raise_error(/Symbol alias name is duplicated./)
    end
  end
end
