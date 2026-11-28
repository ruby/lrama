# frozen_string_literal: true

RSpec.describe Lrama::Grammar do
  let(:rule_counter) { Lrama::Grammar::Counter.new(0) }
  let(:grammar) { described_class.new(rule_counter, false, {}) }

  describe '#set_start_nterm' do
    let(:grammar_file) { Lrama::Lexer::GrammarFile.new("test.y", "") }

    it 'sets the start non-terminal' do
      token = Lrama::Lexer::Token::Ident.new(s_value: 'start', location: Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 1, last_line: 1, last_column: 5))
      expect { grammar.set_start_nterm(token) }.not_to raise_error
    end

    it 'raises an error if start non-terminal is already set' do
      token1 = Lrama::Lexer::Token::Ident.new(s_value: 'start1', location: Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 1, last_line: 1, last_column: 7))
      token2 = Lrama::Lexer::Token::Ident.new(s_value: 'start2', location: Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 4, first_column: 1, last_line: 4, last_column: 7))
      grammar.set_start_nterm(token1)

      expect {grammar.set_start_nterm(token2)}.to raise_error(RuntimeError, "Start non-terminal is already set to start1 (line: 1). Cannot set to start2 (line: 4).")
    end
  end

  describe '#validate!' do
    let(:grammar_file) { Lrama::Lexer::GrammarFile.new('parse.y', '') }

    context 'when all rules have valid precedence' do
      before do
        number = grammar.add_term(id: symbol_id('tNUMBER'))
        string = grammar.add_term(id: symbol_id('tSTRING'))
        grammar.add_precedence(number, 1, 10)
        grammar.add_precedence(string, 1, 11)
        grammar.fill_symbol_number
      end

      it 'does not raise error' do
        expect { grammar.validate! }.not_to raise_error
      end
    end

    context 'when a rule has precedence on lhs (which should be term)' do
      before do
        location = Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 0, last_line: 1, last_column: 4)
        nterm = grammar.add_nterm(id: symbol_id('expression'), location: location)
        grammar.add_precedence(nterm, 1, 10)
        grammar.fill_symbol_number
      end

      it 'raises error with message' do
        expect { grammar.validate! }
          .to raise_error('[BUG] Precedence expression (line: 10) is defined for nonterminal symbol (line: 1). Precedence can be defined for only terminal symbol.')
      end
    end

    context 'when multiple rules have precedence on lhs' do
      before do
        location1 = Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 0, last_line: 1, last_column: 10)
        location2 = Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 2, first_column: 0, last_line: 2, last_column: 9)
        nterm1 = grammar.add_nterm(id: symbol_id('expression'), location: location1)
        nterm2 = grammar.add_nterm(id: symbol_id('statement'), location: location2)
        grammar.add_precedence(nterm1, 1, 10)
        grammar.add_precedence(nterm2, 2, 20)
        grammar.fill_symbol_number
      end

      it 'raises error with all messages joined' do
        expected_message = "[BUG] Precedence expression (line: 10) is defined for nonterminal symbol (line: 1). Precedence can be defined for only terminal symbol.\n" \
                           '[BUG] Precedence statement (line: 20) is defined for nonterminal symbol (line: 2). Precedence can be defined for only terminal symbol.'

        expect { grammar.validate! }.to raise_error(expected_message)
      end
    end

    context 'when a rule has term as lhs' do
      before do
        lhs_term = Lrama::Grammar::Symbol.new(
          id: symbol_id('+'),
          term: true
        )
        rule = Lrama::Grammar::Rule.new(
          id: 1,
          _lhs: Lrama::Grammar::Symbol::Id.new(name: '+', kind: :ident),
          _rhs: [],
          rhs: [],
          token_code: nil,
          lineno: 15
        )
        rule.lhs = lhs_term
        grammar.rules = [rule]
      end

      it 'raises error with message' do
        expect { grammar.validate! }
          .to raise_error('[BUG] LHS of + -> ε (line: 15) is terminal symbol. It should be nonterminal symbol.')
      end
    end

    context 'when multiple rules have term as lhs' do
      before do
        lhs1 = Lrama::Grammar::Symbol.new(id: symbol_id('+'), term: true)
        lhs2 = Lrama::Grammar::Symbol.new(id: symbol_id('expr'), term: false)
        lhs3 = Lrama::Grammar::Symbol.new(id: symbol_id('-'), term: true)
        rule1 = Lrama::Grammar::Rule.new(
          id: 1,
          _lhs: Lrama::Grammar::Symbol::Id.new(name: '+', kind: :ident),
          rhs: [],
          token_code: nil,
          lineno: 15
        )
        rule2 = Lrama::Grammar::Rule.new(
          id: 2,
          _lhs: Lrama::Grammar::Symbol::Id.new(name: 'expr', kind: :ident),
          rhs: [],
          token_code: nil,
          lineno: 20
        )
        rule3 = Lrama::Grammar::Rule.new(
          id: 3,
          _lhs: Lrama::Grammar::Symbol::Id.new(name: '-', kind: :ident),
          rhs: [],
          token_code: nil,
          lineno: 25
        )
        rule1.lhs = lhs1
        rule2.lhs = lhs2
        rule3.lhs = lhs3

        grammar.rules = [rule1, rule2, rule3]
      end

      it 'raises error with all messages joined' do
        expected_message = "[BUG] LHS of + -> ε (line: 15) is terminal symbol. It should be nonterminal symbol.\n" \
                            '[BUG] LHS of - -> ε (line: 25) is terminal symbol. It should be nonterminal symbol.'

        expect { grammar.validate! }
          .to raise_error(expected_message)
      end
    end

    context 'when rules array is empty' do
      it 'does not raise error' do
        grammar.rules = []

        expect { grammar.validate! }.not_to raise_error
      end
    end

    context 'when there are no duplicates' do
      before do
        string = grammar.add_term(id: symbol_id('tSTRING'))
        number = grammar.add_term(id: symbol_id('tNUMBER'))
        ident = grammar.add_term(id: symbol_id('tIDENT'))
        grammar.add_left(string, 0, 7)
        grammar.add_right(number, 1, 8)
        grammar.add_nonassoc(ident, 2, 9)
        grammar.fill_symbol_number
      end

      it 'does not raise an error' do
        expect { grammar.validate! }.not_to raise_error
      end
    end

    context 'when there is one duplicate' do
      before do
        term = grammar.add_term(id: symbol_id('tSTRING'))
        grammar.add_left(term, 0, 7)
        grammar.add_precedence(term, 1, 8) # This is a duplicate
        grammar.fill_symbol_number
      end

      it 'raises an error with the correct message' do
        expected_message = "%precedence redeclaration for tSTRING (line: 8) previous declaration was %left (line: 7)"

        expect { grammar.validate! }
          .to raise_error(RuntimeError, expected_message)
      end
    end

    context 'when there are multiple duplicates of the same token' do
      before do
        term = grammar.add_term(id: symbol_id('tSTRING'))
        grammar.add_left(term, 0, 7)
        grammar.add_precedence(term, 1, 8)
        grammar.add_nonassoc(term, 3, 10)
        grammar.fill_symbol_number
      end

      it 'raises an error with all duplicate messages' do
        expected_messages = [
          "%precedence redeclaration for tSTRING (line: 8) previous declaration was %left (line: 7)",
          "%nonassoc redeclaration for tSTRING (line: 10) previous declaration was %left (line: 7)"
        ]

        expect { grammar.validate! }
          .to raise_error(RuntimeError, expected_messages.join("\n"))
      end
    end

    context 'when there are duplicates of different tokens' do
      before do
        string = grammar.add_term(id: symbol_id('tSTRING'))
        number = grammar.add_term(id: symbol_id('tNUMBER'))
        grammar.add_left(string, 0, 7)
        grammar.add_precedence(string, 1, 8)
        grammar.add_left(number, 2, 9)
        grammar.add_nonassoc(number, 3, 10)
        grammar.fill_symbol_number
      end

      it 'raises an error with messages for all duplicate tokens' do
        expect { grammar.validate! }
          .to raise_error(RuntimeError) do |error|
            expect(error.message).to include("%precedence redeclaration for tSTRING (line: 8)")
            expect(error.message).to include("%nonassoc redeclaration for tNUMBER (line: 10)")
            expect(error.message.lines.count).to eq(2)
          end
      end
    end

    context 'when the same token appears multiple times with mixed duplicates and non-duplicates' do
      before do
        string = grammar.add_term(id: symbol_id('tSTRING'))
        number = grammar.add_term(id: symbol_id('tNUMBER'))
        ident = grammar.add_term(id: symbol_id('tIDENT'))
        grammar.add_left(string, 0, 7)
        grammar.add_precedence(string, 1, 8)
        grammar.add_nonassoc(string, 2, 10)
        grammar.add_left(number, 3, 7)
        grammar.add_nonassoc(number, 4, 10)
        grammar.add_right(ident, 5, 9)
        grammar.fill_symbol_number
      end

      it 'only reports errors for duplicated tokens' do
        expect { grammar.validate! }
          .to raise_error(RuntimeError) do |error|
            expect(error.message).to include("tSTRING")
            expect(error.message).to include("tNUMBER")
            expect(error.message).not_to include("tIDENT")
          end
      end
    end
  end

  describe '#no_inline' do
    it 'defaults to false' do
      expect(grammar.no_inline).to be false
    end

    it 'can be set to true' do
      grammar.no_inline = true
      expect(grammar.no_inline).to be true
    end

    it 'prepares recursive inline rules as ordinary nonterminals' do
      source = <<~GRAMMAR
        %rule %inline repeat: 'x' repeat | %empty ;
        %%
        program: repeat ;
      GRAMMAR
      grammar = Lrama::Parser.new(source, "repeat.y").parse
      grammar.no_inline = true
      grammar.prepare
      alternatives = grammar.rules.select { |rule| rule.lhs.name == "repeat" }
      expect(alternatives.map { |rule| rule.rhs.map(&:name) }).to eq([["'x'", "repeat"], []])
    end

    it 'instantiates inline rules by arity, including rules from the standard library' do
      source = <<~GRAMMAR
        %token X Y
        %rule %inline helper: X ;
        %rule %inline helper(A): A ;
        %rule %inline helper(A, B): B A ;
        %%
        program: helper helper(X) helper(X, Y) ioption(X) ;
      GRAMMAR
      grammar = Lrama::Parser.new(source, "overloads.y").parse
      path = Lrama::Command::STDLIB_FILE_PATH
      stdlib = Lrama::Parser.new(File.read(path), path).parse
      grammar.prepend_parameterized_rules(stdlib.parameterized_rules)
      grammar.no_inline = true
      grammar.prepare

      rules = grammar.rules.group_by { |rule| rule.lhs.name }
      expect(rules.fetch("program").first.rhs.map(&:name)).to eq(["helper", "helper_X", "helper_X_Y", "ioption_X"])
      expect(rules.fetch("helper_X_Y").first.rhs.map(&:name)).to eq(["Y", "X"])
      expect(rules.fetch("ioption_X").map { |rule| rule.rhs.map(&:name) }).to eq([[], ["X"]])
    end
  end

  describe '#prepare' do
    context 'when an inline alternative is empty' do
      let(:source) do
        <<~GRAMMAR
          %rule %inline opt: %empty | '-' ;
          %rule observe(X): X { seen(@1); } ;
          %rule pass(X): X ;
          %rule ignore(X): 'y' ;
          %%
          program: #{entry} ;
          expr: opt 'x' ;
        GRAMMAR
      end
      let(:grammar) { Lrama::Parser.new(source, "locations.y").parse }
      let(:empty_alternative) { grammar.rules.find { |rule| rule.lhs.name == "expr" && rule.rhs.size == 1 } }

      context 'when another ordinary rule uses locations' do
        let(:entry) { "expr { seen(@1); }" }

        it 'preserves the default location of the expanded rule' do
          grammar.prepare
          expect(empty_alternative.token_code.s_value).to include("YYLLOC_DEFAULT")
        end
      end

      context 'when an instantiated parameterized rule uses locations' do
        let(:entry) { "pass(observe(expr))" }

        it 'preserves the default location of the expanded rule' do
          grammar.prepare
          expect(empty_alternative.token_code.s_value).to include("YYLLOC_DEFAULT")
        end
      end

      context 'when a parameterized rule with locations is never instantiated' do
        let(:entry) { "expr ignore(observe(expr))" }

        it 'keeps the lexer signature without a location argument' do
          grammar.prepare
          expect(grammar.locations).to be(false)
          expect(empty_alternative.token_code).to be_nil
        end
      end
    end

    it 'allows a start symbol with a parameterized inline rule of the same name' do
      source = <<~GRAMMAR
        %rule %inline first(X): X ;
        %start first
        %%
        first: first 'x' | 'x' ;
      GRAMMAR
      grammar = Lrama::Parser.new(source, "start.y").parse
      expect { grammar.prepare }.not_to raise_error
    end

    it 'points to the reference that closes an inline cycle' do
      source = <<~GRAMMAR
        %rule %inline a: b ;
        %rule %inline b: a ;
        %%
        program: a ;
      GRAMMAR
      grammar = Lrama::Parser.new(source, "cycle.y").parse
      expect { grammar.prepare }.to raise_error(
        Lrama::Grammar::Inline::Validator::RecursiveInlineError, /cycle\.y:2:17: .*a -> b -> a/
      )
    end

    it 'points to the inline symbol in the start directive' do
      source = <<~GRAMMAR
        %rule %inline first: 'x' ;
        %start first
        %%
        program: first ;
      GRAMMAR
      grammar = Lrama::Parser.new(source, "start.y").parse
      expect { grammar.prepare }.to raise_error(
        Lrama::Grammar::Inline::Validator::StartSymbolInlineError, /start\.y:2:7: Start symbol 'first'/
      )
    end
  end
end
