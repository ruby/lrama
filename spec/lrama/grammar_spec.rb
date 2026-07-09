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
        location = Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 0, last_line: 1, last_column: 4)
        term1 = grammar.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: 'expr', location: location))
        term2 = grammar.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: 'term', location: location))
        grammar.add_precedence(term1, 1, 'tNUMBER', 10)
        grammar.add_precedence(term1, 1, 'tSTRING', 11)
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
        grammar.add_precedence(nterm, 1, 'tNUMBER', 10)
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
        grammar.add_precedence(nterm1, 1, 'tNUMBER', 10)
        grammar.add_precedence(nterm2, 2, 'tSTRING', 20)
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
        expect { grammar.validate! }
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

    context 'when there are no duplicates' do
      before do
        location = Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 0, last_line: 1, last_column: 4)
        term = grammar.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: 'expr', location: location))
        grammar.add_left(term, 0, "tSTRING", 7)
        grammar.add_right(term, 1, "tNUMBER", 8)
        grammar.add_nonassoc(term, 2, "tIDENT", 9)
        grammar.fill_symbol_number
      end

      it 'does not raise an error' do
        expect { grammar.validate! }.not_to raise_error
      end
    end

    context 'when there is one duplicate' do
      before do
        location = Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 0, last_line: 1, last_column: 4)
        term = grammar.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: 'expr', location: location))
        grammar.add_left(term, 0, "tSTRING", 7)
        grammar.add_precedence(term, 1, "tSTRING", 8) # This is a duplicate
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
        location = Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 0, last_line: 1, last_column: 4)
        term = grammar.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: 'expr', location: location))
        grammar.add_left(term, 0, "tSTRING", 7)
        grammar.add_precedence(term, 1, "tSTRING", 8)
        grammar.add_nonassoc(term, 3, "tSTRING", 10)
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
        location = Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 0, last_line: 1, last_column: 4)
        term = grammar.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: 'expr', location: location))
        grammar.add_left(term, 0, "tSTRING", 7)
        grammar.add_precedence(term, 1, "tSTRING", 8)
        grammar.add_left(term, 2, "tNUMBER", 9)
        grammar.add_nonassoc(term, 3, "tNUMBER", 10)
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
        location = Lrama::Lexer::Location.new(grammar_file: grammar_file, first_line: 1, first_column: 0, last_line: 1, last_column: 4)
        term = grammar.add_term(id: Lrama::Lexer::Token::Ident.new(s_value: 'expr', location: location))
        grammar.add_left(term, 0, "tSTRING", 7)
        grammar.add_precedence(term, 1, "tSTRING", 8)
        grammar.add_nonassoc(term, 2, "tSTRING", 10)
        grammar.add_left(term, 3, "tNUMBER", 7)
        grammar.add_nonassoc(term, 4, "tNUMBER", 10)
        grammar.add_right(term, 5, "tIDENT", 9)
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

    context 'when no_inline is true' do
      it 'skips inline rule validation and resolution during prepare' do
        grammar.no_inline = true

        # Mock the parameterized_resolver to have an inline rule with recursion
        # This would normally raise an error, but with no_inline=true it should be skipped
        allow(grammar).to receive(:validate_inline_rules)
        allow(grammar).to receive(:resolve_inline_rules)

        # prepare should not call validate_inline_rules or resolve_inline_rules
        grammar.no_inline = true

        expect(grammar).not_to receive(:validate_inline_rules)
        expect(grammar).not_to receive(:resolve_inline_rules)
      end
    end
  end
end
