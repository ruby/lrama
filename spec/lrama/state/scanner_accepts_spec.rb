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

    it "includes layout tokens in every parser-state accept set" do
      div = token_pattern("DIV", "/", 0)
      layout = token_pattern("YYLAYOUT_WS", "[ \\t]+", 1)
      scanner_fsa = Lrama::ScannerFSA.new([div, layout])
      state = parser_state(0, ["DIV"])
      scanner_accepts = Lrama::State::ScannerAccepts.new(
        [state],
        scanner_fsa,
        lex_prec,
        Lrama::LengthPrecedences.new(lex_prec),
        layout_token_names: Set["YYLAYOUT_WS"]
      )

      scanner_accepts.build

      accepting = scanner_fsa.states.find {|s| s.accepting_tokens.map(&:name).include?("YYLAYOUT_WS") }
      expect(scanner_accepts[0, accepting.id].name).to eq("YYLAYOUT_WS")
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
      parser_rows = scanner_accepts.table.reject do |(parser_state_id, _scanner_state_id), _token|
        parser_state_id == Lrama::State::ScannerAccepts::FALLBACK_ROW_ID
      end
      expect(parser_rows).to be_empty
      expect(scanner_accepts.fallback_table.values.map(&:name)).to contain_exactly("A")
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

    it "keeps an empty outcome distinct from an unresolved conflict" do
      resolver = Lrama::State::ScannerAccepts::ProfileResolver.new(
        Lrama::Grammar::LexPrec.new,
        Lrama::LengthPrecedences.new(Lrama::Grammar::LexPrec.new)
      )

      outcome = resolver.resolve(Set.new, nil, Set.new)

      expect(outcome).to be_empty
      expect(outcome).not_to be_unresolved
    end

    it "uses same-token autolength without fallback mode" do
      resolver = Lrama::State::ScannerAccepts::ProfileResolver.new(
        Lrama::Grammar::LexPrec.new,
        Lrama::LengthPrecedences.new(Lrama::Grammar::LexPrec.new)
      )

      outcome = resolver.resolve(Set["ID"], "ID", Set["ID"])

      expect(outcome).to be_resolved
      expect(outcome.token_name).to eq("ID")
    end

    it "uses declaration order only in fallback mode" do
      lex_prec = Lrama::Grammar::LexPrec.new
      length_prec = Lrama::LengthPrecedences.new(lex_prec)
      normal = Lrama::State::ScannerAccepts::ProfileResolver.new(
        lex_prec,
        length_prec,
        token_order: { "A" => 1, "B" => 0 }
      )
      fallback = Lrama::State::ScannerAccepts::ProfileResolver.new(
        lex_prec,
        length_prec,
        fallback: true,
        token_order: { "A" => 1, "B" => 0 }
      )

      expect(normal.resolve(Set.new, nil, Set["A", "B"])).to be_unresolved
      expect(fallback.resolve(Set.new, nil, Set["A", "B"]).token_name).to eq("B")
    end

    it "uses explicit identity precedence before fallback declaration order" do
      lex_prec = Lrama::Grammar::LexPrec.new
      lex_prec.add_rule(left_token: ident("A"), operator: Lrama::Grammar::LexPrec::IDENTITY_RIGHT, right_token: ident("B"), lineno: 1)
      fallback = Lrama::State::ScannerAccepts::ProfileResolver.new(
        lex_prec,
        Lrama::LengthPrecedences.new(lex_prec),
        fallback: true,
        token_order: { "A" => 0, "B" => 1 }
      )

      expect(fallback.resolve(Set.new, nil, Set["A", "B"]).token_name).to eq("B")
    end
  end

  describe Lrama::State::ScannerAccepts::CompatibilityChecker do
    let(:rangle) { token_pattern("RANGLE", ">", 0) }
    let(:rshift) { token_pattern("RSHIFT", ">>", 1) }
    let(:scanner_fsa) { Lrama::ScannerFSA.new([rangle, rshift]) }
    let(:lex_prec) { Lrama::Grammar::LexPrec.new }
    let(:checker) do
      described_class.new(scanner_fsa, lex_prec, Lrama::LengthPrecedences.new(lex_prec))
    end

    it "treats a missing match on one side as irrelevant" do
      a = token_pattern("A", "a", 0)
      b = token_pattern("B", "b", 1)
      fsa = Lrama::ScannerFSA.new([a, b])
      checker = described_class.new(fsa, lex_prec, Lrama::LengthPrecedences.new(lex_prec))

      expect(checker.compatible?(Set["A"], Set["B"])).to be true
    end

    it "rejects different resolved outcomes when both sides match" do
      expect(checker.compatible?(Set["RANGLE"], Set["RSHIFT"])).to be false
    end

    it "rejects resolved versus unresolved outcomes" do
      a = token_pattern("A", "a", 0)
      b = token_pattern("B", "a", 1)
      fsa = Lrama::ScannerFSA.new([a, b])
      checker = described_class.new(fsa, lex_prec, Lrama::LengthPrecedences.new(lex_prec))

      expect(checker.compatible?(Set["A"], Set["A", "B"])).to be false
    end

    it "accepts unresolved outcomes on both sides" do
      a = token_pattern("A", "a", 0)
      b = token_pattern("B", "a", 1)
      fsa = Lrama::ScannerFSA.new([a, b])
      checker = described_class.new(fsa, lex_prec, Lrama::LengthPrecedences.new(lex_prec))

      expect(checker.compatible?(Set["A", "B"], Set["A", "B"])).to be true
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

    it "does not expand tokens tied only through layout injection" do
      div = token_pattern("DIV", "/", 0)
      layout = token_pattern("YYLAYOUT_WS", "[ \\t]+", 1)
      layout_alias = token_pattern("LAYOUT_ALIAS", "[ \\t]+", 2)
      scanner_fsa = Lrama::ScannerFSA.new([div, layout, layout_alias])
      lex_prec = Lrama::Grammar::LexPrec.new
      lex_tie = Lrama::Grammar::LexTie.new
      lex_tie.add_tie("YYLAYOUT_WS", "LAYOUT_ALIAS")
      scanner_accepts = Lrama::State::ScannerAccepts.new(
        [parser_state(0, ["DIV"])],
        scanner_fsa,
        lex_prec,
        Lrama::LengthPrecedences.new(lex_prec),
        lex_tie,
        layout_token_names: Set["YYLAYOUT_WS"]
      )

      acc_sp = scanner_accepts.send(:compute_acc_sp, parser_state(0, ["DIV"]))

      expect(acc_sp).to contain_exactly("DIV", "YYLAYOUT_WS")
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
