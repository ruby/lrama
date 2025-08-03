# frozen_string_literal: true

RSpec.describe Lrama::Grammar do
  let(:rule_counter) { Lrama::Grammar::Counter.new(0) }
  let(:grammar) { described_class.new(rule_counter, false, {}) }

  describe '#validate!' do
    context 'when all rules have valid precedence' do
      before do
        lhs1 = Lrama::Grammar::Symbol.new(id: Lrama::Lexer::Token::Ident.new(s_value: 'expr'), term: false)
        lhs2 = Lrama::Grammar::Symbol.new(id: Lrama::Lexer::Token::Ident.new(s_value: 'term'), term: false)
        rule1 = Lrama::Grammar::Rule.new(
          id: 1,
          _lhs: Lrama::Lexer::Token::Ident.new(s_value: 'expr'),
          _rhs: [],
          token_code: nil,
          lineno: 1
        )
        rule1.lhs = lhs1
        rule2 = Lrama::Grammar::Rule.new(
          id: 2,
          _lhs: Lrama::Lexer::Token::Ident.new(s_value: 'term'),
          _rhs: [],
          token_code: nil,
          lineno: 2
        )
        rule2.lhs = lhs2
        grammar.rules = [rule1, rule2]
      end

      it 'does not raise error' do
        expect { grammar.validate! }.not_to raise_error
      end
    end

    context 'when a rule has precedence on lhs (which should be term)' do
      before do
        lhs_with_precedence = Lrama::Grammar::Symbol.new(
          id: Lrama::Lexer::Token::Ident.new(s_value: 'expression'),
          term: false
        )
        lhs_with_precedence.precedence = Lrama::Grammar::Precedence.new(type: :left, precedence: 1, lineno: 10)

        rule = Lrama::Grammar::Rule.new(
          id: 1,
          _lhs: Lrama::Lexer::Token::Ident.new(s_value: 'expression'),
          _rhs: [],
          token_code: nil,
          lineno: 1
        )
        rule.lhs = lhs_with_precedence

        grammar.rules = [rule]
      end

      it 'raises error with message' do
        expect { grammar.validate! }
          .to raise_error('[BUG] Precedence expression (line: 10) is defined for nonterminal symbol (line: 1). Precedence can be defined for only terminal symbol.')
      end
    end

    context 'when multiple rules have precedence on lhs' do
      before do
        lhs1 = Lrama::Grammar::Symbol.new(
          id: Lrama::Lexer::Token::Ident.new(s_value: 'expression'),
          term: false
        )
        lhs2 = Lrama::Grammar::Symbol.new(
          id: Lrama::Lexer::Token::Ident.new(s_value: 'statement'),
          term: false
        )
        rule1 = Lrama::Grammar::Rule.new(
          id: 1,
          _lhs: Lrama::Lexer::Token::Ident.new(s_value: 'expression'),
          _rhs: [],
          token_code: nil,
          lineno: 1
        )
        rule2 = Lrama::Grammar::Rule.new(
          id: 2,
          _lhs: Lrama::Lexer::Token::Ident.new(s_value: 'statement'),
          _rhs: [],
          token_code: nil,
          lineno: 2
        )
        lhs1.precedence = Lrama::Grammar::Precedence.new(type: :left, precedence: 1, lineno: 10)
        lhs2.precedence = Lrama::Grammar::Precedence.new(type: :right, precedence: 2, lineno: 20)
        rule1.lhs = lhs1
        rule2.lhs = lhs2
        grammar.rules = [rule1, rule2]
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
