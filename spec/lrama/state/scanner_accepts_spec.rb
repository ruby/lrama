# frozen_string_literal: true

RSpec.describe Lrama::State::ScannerAccepts do
  def ident(name)
    Lrama::Lexer::Token::Ident.new(s_value: name)
  end

  def token_pattern(name, regex, order)
    Lrama::Grammar::TokenPattern.new(
      id: ident(name),
      pattern: Lrama::Lexer::Token::Regex.new(s_value: "/#{regex}/"),
      lineno: 1,
      definition_order: order
    )
  end

  def shift_for(name)
    symbol = instance_double(
      Lrama::Grammar::Symbol,
      term?: true,
      id: ident(name)
    )
    instance_double(Lrama::State::Action::Shift, next_sym: symbol)
  end

  def parser_state(id, token_names)
    instance_double(
      Lrama::State,
      id: id,
      term_transitions: token_names.map {|name| shift_for(name) },
      reduces: []
    )
  end

  describe "#build and #[]" do
    let(:rangle) { token_pattern("RANGLE", ">", 0) }
    let(:rshift) { token_pattern("RSHIFT", ">>", 1) }
    let(:scanner_fsa) { Lrama::ScannerFSA.new([rangle, rshift]) }
    let(:lex_prec) { Lrama::Grammar::LexPrec.new }
    let(:length_prec) { Lrama::LengthPrecedences.new(lex_prec) }

    it "builds scanner_accepts from parser acceptable tokens" do
      state = parser_state(0, ["RANGLE"])
      scanner_accepts = Lrama::State::ScannerAccepts.new(
        [state],
        scanner_fsa,
        lex_prec,
        length_prec
      )

      scanner_accepts.build

      accepting = scanner_fsa.states.find {|s| s.accepting_tokens.map(&:name).include?("RANGLE") }
      expect(scanner_accepts[0, accepting.id].name).to eq("RANGLE")
    end
  end

  describe "complete conflict resolution" do
    it "does not use declaration order for unresolved identity conflicts" do
      tokens = [
        token_pattern("A", "a", 0),
        token_pattern("B", "a", 1),
        token_pattern("C", "a", 2)
      ]
      scanner_fsa = Lrama::ScannerFSA.new(tokens)
      lex_prec = Lrama::Grammar::LexPrec.new
      scanner_accepts = Lrama::State::ScannerAccepts.new(
        [parser_state(0, ["A", "B", "C"])],
        scanner_fsa,
        lex_prec,
        Lrama::LengthPrecedences.new(lex_prec)
      )

      scanner_accepts.build

      expect(scanner_accepts.unresolved_conflicts?).to be true
      expect(scanner_accepts.table).to be_empty
    end

    it "selects a unique explicitly declared identity winner" do
      tokens = [
        token_pattern("A", "a", 0),
        token_pattern("B", "a", 1),
        token_pattern("C", "a", 2)
      ]
      scanner_fsa = Lrama::ScannerFSA.new(tokens)
      lex_prec = Lrama::Grammar::LexPrec.new
      lex_prec.add_rule(left_token: ident("A"), operator: Lrama::Grammar::LexPrec::IDENTITY_RIGHT, right_token: ident("C"), lineno: 1)
      lex_prec.add_rule(left_token: ident("B"), operator: Lrama::Grammar::LexPrec::IDENTITY_RIGHT, right_token: ident("C"), lineno: 1)
      scanner_accepts = Lrama::State::ScannerAccepts.new(
        [parser_state(0, ["A", "B", "C"])],
        scanner_fsa,
        lex_prec,
        Lrama::LengthPrecedences.new(lex_prec)
      )

      scanner_accepts.build

      accepting = scanner_fsa.states.find(&:accepting?)
      expect(scanner_accepts[0, accepting.id].name).to eq("C")
      expect(scanner_accepts.unresolved_conflicts?).to be false
    end

    it "keeps conflicts finite for looped scanner states" do
      id = token_pattern("ID", "[a-z]+", 0)
      kw = token_pattern("IF", "if", 1)
      scanner_fsa = Lrama::ScannerFSA.new([id, kw])
      lex_prec = Lrama::Grammar::LexPrec.new
      scanner_accepts = Lrama::State::ScannerAccepts.new(
        [parser_state(0, ["ID", "IF"])],
        scanner_fsa,
        lex_prec,
        Lrama::LengthPrecedences.new(lex_prec)
      )

      scanner_accepts.build

      expect(scanner_accepts.conflicts.size).to be < 10
    end
  end

  describe "lexical ties" do
    it "expands acc(sp) through tie closure" do
      id = token_pattern("ID", "[a-z]+", 0)
      kw = token_pattern("IF", "if", 1)
      scanner_fsa = Lrama::ScannerFSA.new([id, kw])
      lex_prec = Lrama::Grammar::LexPrec.new
      lex_prec.add_rule(left_token: ident("ID"), operator: Lrama::Grammar::LexPrec::IDENTITY_RIGHT_LONGEST, right_token: ident("IF"), lineno: 1)
      lex_tie = Lrama::Grammar::LexTie.new
      lex_tie.add_tie("ID", "IF")
      scanner_accepts = Lrama::State::ScannerAccepts.new(
        [parser_state(0, ["ID"])],
        scanner_fsa,
        lex_prec,
        Lrama::LengthPrecedences.new(lex_prec),
        lex_tie
      )

      scanner_accepts.build

      accepting = scanner_fsa.states.find {|state| state.accepting_tokens.map(&:name).include?("IF") }
      expect(scanner_accepts[0, accepting.id].name).to eq("IF")
    end
  end

  describe "pure reduce states" do
    let(:rangle) { token_pattern("RANGLE", ">", 0) }
    let(:rshift) { token_pattern("RSHIFT", ">>", 1) }
    let(:scanner_fsa) { Lrama::ScannerFSA.new([rangle, rshift]) }
    let(:lex_prec) { Lrama::Grammar::LexPrec.new }
    let(:length_prec) { Lrama::LengthPrecedences.new(lex_prec) }
    let(:reduce) { instance_double(Lrama::State::Action::Reduce) }
    let(:parser_state) do
      instance_double(
        Lrama::State,
        term_transitions: [],
        reduces: [reduce],
      )
    end

    it "uses propagated item lookaheads when explicit reduce lookahead is absent" do
      allow(parser_state).to receive(:acceptable_pslr_reduce_lookahead).with(reduce).and_return([
        instance_double(Lrama::Grammar::Symbol, id: ident("RANGLE")),
        instance_double(Lrama::Grammar::Symbol, id: ident("RSHIFT")),
      ])

      scanner_accepts = Lrama::State::ScannerAccepts.new(
        [parser_state],
        scanner_fsa,
        lex_prec,
        length_prec
      )

      expect(scanner_accepts.send(:compute_acc_sp, parser_state).to_a).to contain_exactly("RANGLE", "RSHIFT")
    end
  end
end
