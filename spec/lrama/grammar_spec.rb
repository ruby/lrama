# frozen_string_literal: true

RSpec.describe Lrama::Grammar do
  let(:rule_counter) { Lrama::Grammar::Counter.new(0) }
  let(:grammar) { described_class.new(rule_counter, false, {}) }

  describe '#validate!' do
    let(:grammar_file) { Lrama::Lexer::GrammarFile.new('parse.y', '') }

    context 'when all rules have valid precedence' do
      before do
        location = Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 0, last_line: 1, last_column: 4)
        term1 = grammar.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: 'expr', location: location))
        term2 = grammar.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: 'term', location: location))
        grammar.add_precedence(term1, 1, 10)
        grammar.add_precedence(term1, 1, 11)
        grammar.fill_symbol_number
      end

      it 'does not raise error' do
        expect { grammar.validate! }.not_to raise_error
      end
    end

    context 'when a rule has precedence on lhs (which should be term)' do
      before do
        location = Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 0, last_line: 1, last_column: 4)
        nterm = grammar.add_nterm(id: Lrama::Lexer::Token::Ident.new(s_value: 'expression', location: location))
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
        nterm1 = grammar.add_nterm(id: Lrama::Lexer::Token::Ident.new(s_value: 'expression', location: location1))
        nterm2 = grammar.add_nterm(id: Lrama::Lexer::Token::Ident.new(s_value: 'statement', location: location2))
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
  end

  context 'when a rule has term as lhs' do
    before do
      lhs_term = Lrama::Grammar::Symbol.new(
        id: Lrama::Lexer::Token::Ident.new(s_value: '+'),
        term: true
      )
      rule = Lrama::Grammar::Rule.new(
        id: 1,
        _lhs: Lrama::Lexer::Token::Ident.new(s_value: '+'),
        _rhs: [],
        rhs: [],
        token_code: nil,
        lineno: 15
      )
      rule.lhs = lhs_term
      grammar.rules = [rule]
    end

    it 'raises error with message' do
      expect { grammar.send(:validate!) }
        .to raise_error('[BUG] LHS of + -> ε (line: 15) is terminal symbol. It should be nonterminal symbol.')
    end
  end

  context 'when multiple rules have term as lhs' do
    before do
      lhs1 = Lrama::Grammar::Symbol.new(id: Lrama::Lexer::Token::Ident.new(s_value: '+'), term: true)
      lhs2 = Lrama::Grammar::Symbol.new(id: Lrama::Lexer::Token::Ident.new(s_value: 'expr'), term: false)
      lhs3 = Lrama::Grammar::Symbol.new(id: Lrama::Lexer::Token::Ident.new(s_value: '-'), term: true)
      rule1 = Lrama::Grammar::Rule.new(
        id: 1,
        _lhs: Lrama::Lexer::Token::Ident.new(s_value: '+'),
        rhs: [],
        token_code: nil,
        lineno: 15
      )
      rule2 = Lrama::Grammar::Rule.new(
        id: 2,
        _lhs: Lrama::Lexer::Token::Ident.new(s_value: 'expr'),
        rhs: [],
        token_code: nil,
        lineno: 20
      )
      rule3 = Lrama::Grammar::Rule.new(
        id: 3,
        _lhs: Lrama::Lexer::Token::Ident.new(s_value: '-'),
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
end
