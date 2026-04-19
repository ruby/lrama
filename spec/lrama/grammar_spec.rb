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

    context 'when PSLR state member is not a valid C identifier' do
      before do
        grammar.define = {
          'lr.type' => 'pslr',
          'api.pslr.state-member' => 'current-state'
        }
      end

      it 'raises an error with the invalid member name' do
        expect { grammar.validate! }
          .to raise_error(RuntimeError, '%define api.pslr.state-member must be a valid C identifier, got "current-state".')
      end
    end

    context 'when PSLR max states is not an integer' do
      before do
        grammar.define = {
          'lr.type' => 'pslr',
          'pslr.max-states' => 'many'
        }
      end

      it 'raises an error with the invalid value' do
        expect { grammar.validate! }
          .to raise_error(RuntimeError, '%define pslr.max-states must be an integer, got "many".')
      end
    end

    context 'when PSLR max state ratio is smaller than one' do
      before do
        grammar.define = {
          'lr.type' => 'pslr',
          'pslr.max-state-ratio' => '0.5'
        }
      end

      it 'raises an error with the invalid ratio' do
        expect { grammar.validate! }
          .to raise_error(RuntimeError, '%define pslr.max-state-ratio must be greater than or equal to 1.0, got "0.5".')
      end
    end
  end

  describe "#finalize_lexical_ties!" do
    def build_pslr_grammar(source)
      grammar = Lrama::Parser.new(source, "lex_tie.y").parse
      grammar.prepare
      grammar.validate!
      grammar
    end

    it "keeps token-token ties even without a scanner conflict" do
      grammar = build_pslr_grammar(<<~GRAMMAR)
        %define lr.type pslr
        %token-pattern A /a/
        %token-pattern B /b/
        %lex-tie A B
        %%
        start: A | B ;
      GRAMMAR

      grammar.finalize_lexical_ties!(Lrama::ScannerFSA.new(grammar.token_patterns))

      expect(grammar.lex_tie.tied?("A", "B")).to be true
    end

    it "limits set-set ties to scanner-conflicting pairs" do
      grammar = build_pslr_grammar(<<~GRAMMAR)
        %define lr.type pslr
        %token-pattern RANGLE />/
        %token-pattern RSHIFT />>/
        %token-pattern DOT /\\./
        %token-pattern COMMA /,/
        %symbol-set punct RANGLE RSHIFT DOT COMMA
        %lex-tie punct punct
        %%
        start: RANGLE | RSHIFT | DOT | COMMA ;
      GRAMMAR

      grammar.finalize_lexical_ties!(Lrama::ScannerFSA.new(grammar.token_patterns))

      expect(grammar.lex_tie.tied?("RANGLE", "RSHIFT")).to be true
      expect(grammar.lex_tie.tied?("DOT", "COMMA")).to be false
    end

    it "limits set-token ties to scanner-conflicting pairs" do
      grammar = build_pslr_grammar(<<~GRAMMAR)
        %define lr.type pslr
        %token-pattern ID /[a-z]+/
        %token-pattern KW_IF /if/
        %token-pattern KW_WHILE /while/
        %token-pattern PLUS /\\+/
        %symbol-set keywords KW_IF KW_WHILE
        %lex-tie ID keywords
        %lex-tie PLUS keywords
        %%
        start: ID | KW_IF | KW_WHILE | PLUS ;
      GRAMMAR

      grammar.finalize_lexical_ties!(Lrama::ScannerFSA.new(grammar.token_patterns))

      expect(grammar.lex_tie.tied?("ID", "KW_IF")).to be true
      expect(grammar.lex_tie.tied?("ID", "KW_WHILE")).to be true
      expect(grammar.lex_tie.tied?("PLUS", "KW_IF")).to be false
      expect(grammar.lex_tie.tied?("PLUS", "KW_WHILE")).to be false
    end

    it "limits yyall ties to scanner-conflicting pairs" do
      grammar = build_pslr_grammar(<<~GRAMMAR)
        %define lr.type pslr
        %token-pattern PLUS /\\+/
        %token-pattern PLUSPLUS /\\+\\+/
        %token-pattern DOT /\\./
        %token-pattern SLASH /\\//
        %lex-tie yyall yyall
        %%
        start: PLUS | PLUSPLUS | DOT | SLASH ;
      GRAMMAR

      grammar.finalize_lexical_ties!(Lrama::ScannerFSA.new(grammar.token_patterns))

      expect(grammar.lex_tie.tied?("PLUS", "PLUSPLUS")).to be true
      expect(grammar.lex_tie.tied?("DOT", "SLASH")).to be false
      expect(grammar.lex_tie.tied?("PLUS", "DOT")).to be false
      expect(grammar.lex_tie.tied?("SLASH", "PLUSPLUS")).to be false
    end

    it "lets a specific tie override generic yyall no-tie" do
      grammar = build_pslr_grammar(<<~GRAMMAR)
        %define lr.type pslr
        %token-pattern IF /if/
        %token-pattern ID /[a-z]+/
        %symbol-set keywords IF
        %lex-no-tie yyall yyall
        %lex-tie ID keywords
        %%
        start: IF | ID ;
      GRAMMAR

      grammar.finalize_lexical_ties!(Lrama::ScannerFSA.new(grammar.token_patterns))

      expect(grammar.lex_tie.tied?("ID", "IF")).to be true
      expect(grammar.lex_tie.no_tie?("ID", "IF")).to be false
    end

    it "rejects a direct no-tie that conflicts with transitive ties" do
      grammar = build_pslr_grammar(<<~GRAMMAR)
        %define lr.type pslr
        %token-pattern A /a/
        %token-pattern B /a/
        %token-pattern C /a/
        %lex-tie A B
        %lex-tie B C
        %lex-no-tie A C
        %%
        start: A | B | C ;
      GRAMMAR

      expect do
        grammar.finalize_lexical_ties!(Lrama::ScannerFSA.new(grammar.token_patterns))
      end.to raise_error(RuntimeError, /%lex-no-tie A C conflicts/)
    end
  end
end
