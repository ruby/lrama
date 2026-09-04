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
      expect(outcome).to be_current_match
    end

    it "writes a same-token autolength winner to scanner_accepts" do
      id = token_pattern("ID", "a+", 0)
      scanner_fsa = Lrama::ScannerFSA.new([id])
      lex_prec = Lrama::Grammar::LexPrec.new
      scanner_accepts = Lrama::State::ScannerAccepts.new(
        [parser_state(0, ["ID"])],
        scanner_fsa,
        lex_prec,
        Lrama::LengthPrecedences.new(lex_prec)
      )

      scanner_accepts.build

      accepting = scanner_fsa.states.find {|state| state.accepting_tokens.map(&:name) == ["ID"] }
      expect(scanner_accepts[0, accepting.id].name).to eq("ID")
    end

    it "does not report a conflict when a shorter-match winner revisits a current accepting state" do
      x = token_pattern("X", "x", 0)
      y = token_pattern("Y", "y", 1)
      states = 4.times.map {|id| Lrama::ScannerFSA::State.new(id) }
      states[0].add_transition("a", 1)
      states[0].add_transition("b", 2)
      states[1].add_accepting_token(x)
      states[1].add_transition("c", 3)
      states[2].add_accepting_token(y)
      states[2].add_transition("c", 3)
      states[3].add_accepting_token(x)
      states[3].add_accepting_token(y)
      scanner_fsa = instance_double(Lrama::ScannerFSA, states: states, token_patterns: [x, y])
      lex_prec = Lrama::Grammar::LexPrec.new
      lex_prec.add_rule(left_token: ident("X"), operator: Lrama::Grammar::LexPrec::SHORTEST, right_token: ident("X"), lineno: 1)
      lex_prec.add_rule(left_token: ident("X"), operator: Lrama::Grammar::LexPrec::SHORTEST, right_token: ident("Y"), lineno: 2)
      lex_prec.add_rule(left_token: ident("X"), operator: Lrama::Grammar::LexPrec::IDENTITY_RIGHT, right_token: ident("Y"), lineno: 3)
      computer = Lrama::State::ScannerAccepts::CompleteProfileComputer.new(
        scanner_fsa,
        lex_prec,
        Lrama::LengthPrecedences.new(lex_prec),
        Set["X", "Y"]
      )

      computer.compute

      expect(computer.table.fetch(3).name).to eq("Y")
      expect(computer.conflicts).to be_empty
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

    it "preserves explicit identity precedence when fallback length precedence is needed" do
      tokens = [
        token_pattern("X", "x", 0),
        token_pattern("SHORT", "a", 1),
        token_pattern("A", "ab", 2),
        token_pattern("B", "ab", 3)
      ]
      scanner_fsa = Lrama::ScannerFSA.new(tokens)
      lex_prec = Lrama::Grammar::LexPrec.new
      lex_prec.add_rule(left_token: ident("A"), operator: Lrama::Grammar::LexPrec::IDENTITY_RIGHT, right_token: ident("B"), lineno: 1)
      scanner_accepts = Lrama::State::ScannerAccepts.new(
        [parser_state(0, ["X"])],
        scanner_fsa,
        lex_prec,
        Lrama::LengthPrecedences.new(lex_prec)
      )

      scanner_accepts.build

      accepting_ab = scanner_fsa.states.find do |state|
        state.accepting_tokens.map(&:name).sort == ["A", "B"]
      end
      expect(scanner_accepts.fallback_table.fetch(accepting_ab.id).name).to eq("B")
    end

    it "uses declaration order for fallback-only explicit identity cycles" do
      tokens = [
        token_pattern("X", "x", 0),
        token_pattern("A", "a", 1),
        token_pattern("B", "a", 2),
        token_pattern("C", "a", 3)
      ]
      scanner_fsa = Lrama::ScannerFSA.new(tokens)
      lex_prec = Lrama::Grammar::LexPrec.new
      lex_prec.add_rule(left_token: ident("A"), operator: Lrama::Grammar::LexPrec::IDENTITY_RIGHT, right_token: ident("B"), lineno: 1)
      lex_prec.add_rule(left_token: ident("B"), operator: Lrama::Grammar::LexPrec::IDENTITY_RIGHT, right_token: ident("C"), lineno: 2)
      lex_prec.add_rule(left_token: ident("C"), operator: Lrama::Grammar::LexPrec::IDENTITY_RIGHT, right_token: ident("A"), lineno: 3)
      scanner_accepts = Lrama::State::ScannerAccepts.new(
        [parser_state(0, ["X"])],
        scanner_fsa,
        lex_prec,
        Lrama::LengthPrecedences.new(lex_prec)
      )

      scanner_accepts.build

      accepting = scanner_fsa.states.find {|state| state.accepting_tokens.map(&:name).sort == ["A", "B", "C"] }
      expect(scanner_accepts.fallback_table.fetch(accepting.id).name).to eq("A")
    end

    [
      {
        figure: "3.3",
        patterns: { "A" => "a", "B" => "a", "C" => "a" },
        rules: [
          ["A", Lrama::Grammar::LexPrec::IDENTITY_RIGHT, "B"],
          ["B", Lrama::Grammar::LexPrec::IDENTITY_RIGHT, "C"],
          ["C", Lrama::Grammar::LexPrec::IDENTITY_RIGHT, "A"]
        ],
        profile: [[], nil, ["A", "B", "C"]],
        witness: "a"
      },
      {
        figure: "3.4",
        patterns: { "A" => "a", "B" => "ab", "C" => "abc" },
        rules: [
          ["A", Lrama::Grammar::LexPrec::LONGEST, "B"],
          ["B", Lrama::Grammar::LexPrec::LONGEST, "C"],
          ["C", Lrama::Grammar::LexPrec::TOKEN_RIGHT_LENGTH, "A"]
        ],
        profile: [["A", "B"], "B", ["C"]],
        witness: "abc"
      },
      {
        figure: "3.5",
        patterns: { "A" => "a|abc", "B" => "ab" },
        rules: [["A", Lrama::Grammar::LexPrec::SHORTEST, "B"]],
        profile: [["A", "B"], "A", ["A"]],
        witness: "abc"
      }
    ].each do |test_case|
      it "keeps dissertation Figure #{test_case[:figure]} unresolved" do
        tokens = test_case[:patterns].each_with_index.map do |(name, regex), order|
          token_pattern(name, regex, order)
        end
        scanner_fsa = Lrama::ScannerFSA.new(tokens)
        lex_prec = Lrama::Grammar::LexPrec.new
        test_case[:rules].each_with_index do |(left, operator, right), index|
          lex_prec.add_rule(left_token: ident(left), operator: operator, right_token: ident(right), lineno: index + 1)
        end
        scanner_accepts = Lrama::State::ScannerAccepts.new(
          [parser_state(0, test_case[:patterns].keys)],
          scanner_fsa,
          lex_prec,
          Lrama::LengthPrecedences.new(lex_prec)
        )

        scanner_accepts.build

        expect(scanner_accepts.unresolved_conflicts?).to be true
        expect(scanner_accepts.conflicts).to include(
          an_object_having_attributes(
            shorter_tokens: test_case[:profile][0],
            selected_shorter_token: test_case[:profile][1],
            current_tokens: test_case[:profile][2],
            witness: test_case[:witness]
          )
        )
      end
    end
  end

  describe "conflict witnesses" do
    it "attaches an example input to unresolved conflicts" do
      tokens = [
        token_pattern("A", "ab", 0),
        token_pattern("B", "ab", 1)
      ]
      scanner_fsa = Lrama::ScannerFSA.new(tokens)
      lex_prec = Lrama::Grammar::LexPrec.new
      scanner_accepts = Lrama::State::ScannerAccepts.new(
        [parser_state(0, ["A", "B"])],
        scanner_fsa,
        lex_prec,
        Lrama::LengthPrecedences.new(lex_prec)
      )

      scanner_accepts.build

      witnesses = scanner_accepts.conflicts.map(&:witness)
      expect(witnesses).to include("ab")
    end

    it "reports duplicate scanner states with the same profile once using the first witness" do
      tokens = [
        token_pattern("A", "a|b", 0),
        token_pattern("B", "a|b", 1)
      ]
      scanner_fsa = Lrama::ScannerFSA.new(tokens)
      lex_prec = Lrama::Grammar::LexPrec.new
      scanner_accepts = Lrama::State::ScannerAccepts.new(
        [parser_state(0, ["A", "B"])],
        scanner_fsa,
        lex_prec,
        Lrama::LengthPrecedences.new(lex_prec)
      )

      scanner_accepts.build

      expect(scanner_accepts.conflicts.size).to eq(1)
      expect(scanner_accepts.conflicts.first.witness).to eq("a")
    end
  end

  describe "%lex-prec usage tracking" do
    it "marks rules referenced by normal-row resolution and keeps unreferenced ones useless" do
      tokens = [
        token_pattern("A", "a", 0),
        token_pattern("B", "a", 1),
        token_pattern("X", "x", 2),
        token_pattern("Y", "y", 3)
      ]
      scanner_fsa = Lrama::ScannerFSA.new(tokens)
      lex_prec = Lrama::Grammar::LexPrec.new
      lex_prec.add_rule(left_token: ident("A"), operator: Lrama::Grammar::LexPrec::IDENTITY_RIGHT, right_token: ident("B"), lineno: 1)
      lex_prec.add_rule(left_token: ident("X"), operator: Lrama::Grammar::LexPrec::IDENTITY_RIGHT, right_token: ident("Y"), lineno: 2)
      scanner_accepts = Lrama::State::ScannerAccepts.new(
        [parser_state(0, ["A", "B", "X", "Y"])],
        scanner_fsa,
        lex_prec,
        Lrama::LengthPrecedences.new(lex_prec)
      )

      scanner_accepts.build

      useless = lex_prec.useless_rules
      expect(useless.map {|rule| [rule.left_name, rule.right_name] }).to eq([["X", "Y"]])
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

    it "uses lexical precedence when comparing accept sets" do
      expect(checker.compatible?(Set["RANGLE"], Set["RANGLE", "RSHIFT"])).to be false

      lex_prec.add_rule(
        left_token: ident("RSHIFT"),
        operator: Lrama::Grammar::LexPrec::TOKEN_RIGHT,
        right_token: ident("RANGLE"),
        lineno: 1
      )
      precedence_checker = described_class.new(
        scanner_fsa,
        lex_prec,
        Lrama::LengthPrecedences.new(lex_prec)
      )

      expect(precedence_checker.compatible?(Set["RANGLE"], Set["RANGLE", "RSHIFT"])).to be true
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
