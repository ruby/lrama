# frozen_string_literal: true

RSpec.describe Lrama::State::PslrInadequacy do
  let(:mock_state) do
    instance_double(Lrama::State, id: 0)
  end

  let(:mock_conflicting_states) do
    [
      instance_double(Lrama::State, id: 1),
      instance_double(Lrama::State, id: 2)
    ]
  end

  describe "#initialize" do
    it "creates an LR-relative inadequacy" do
      inadequacy = Lrama::State::PslrInadequacy.new(
        type: Lrama::State::PslrInadequacy::LR_RELATIVE,
        state: mock_state,
        conflicting_states: mock_conflicting_states,
        details: { reason: "test" }
      )

      expect(inadequacy.type).to eq(:lr_relative)
      expect(inadequacy.state).to eq(mock_state)
      expect(inadequacy.conflicting_states).to eq(mock_conflicting_states)
      expect(inadequacy.details[:reason]).to eq("test")
    end

    it "creates a PSLR-relative inadequacy" do
      inadequacy = Lrama::State::PslrInadequacy.new(
        type: Lrama::State::PslrInadequacy::PSLR_RELATIVE,
        state: mock_state,
        conflicting_states: mock_conflicting_states,
        details: {}
      )

      expect(inadequacy.type).to eq(:pslr_relative)
    end
  end

  describe "#to_s" do
    it "returns a human-readable description" do
      inadequacy = Lrama::State::PslrInadequacy.new(
        type: Lrama::State::PslrInadequacy::PSLR_RELATIVE,
        state: mock_state,
        conflicting_states: mock_conflicting_states,
        details: {}
      )

      expect(inadequacy.to_s).to include("PSLR Inadequacy")
      expect(inadequacy.to_s).to include("pslr_relative")
      expect(inadequacy.to_s).to include("state 0")
      expect(inadequacy.to_s).to include("1, 2")
    end
  end

  describe "constants" do
    it "defines LR_RELATIVE constant" do
      expect(Lrama::State::PslrInadequacy::LR_RELATIVE).to eq(:lr_relative)
    end

    it "defines PSLR_RELATIVE constant" do
      expect(Lrama::State::PslrInadequacy::PSLR_RELATIVE).to eq(:pslr_relative)
    end
  end
end

RSpec.describe Lrama::State::PslrCompatibilityChecker do
  let(:rangle) do
    id = Lrama::Lexer::Token::Ident.new(s_value: "RANGLE")
    regex = Lrama::Lexer::Token::Regex.new(s_value: "/>/")
    Lrama::Grammar::TokenPattern.new(
      id: id,
      pattern: regex,
      lineno: 1,
      definition_order: 0
    )
  end

  let(:rshift) do
    id = Lrama::Lexer::Token::Ident.new(s_value: "RSHIFT")
    regex = Lrama::Lexer::Token::Regex.new(s_value: "/>>/")
    Lrama::Grammar::TokenPattern.new(
      id: id,
      pattern: regex,
      lineno: 1,
      definition_order: 1
    )
  end

  let(:scanner_fsa) { Lrama::ScannerFSA.new([rangle, rshift]) }
  let(:lex_prec) { Lrama::Grammar::LexPrec.new }
  let(:length_prec) { Lrama::LengthPrecedences.new(lex_prec) }

  describe "#initialize" do
    it "creates a compatibility checker" do
      scanner_accepts = instance_double(Lrama::State::ScannerAccepts)
      checker = Lrama::State::PslrCompatibilityChecker.new(
        scanner_accepts,
        length_prec
      )

      expect(checker).to be_a(Lrama::State::PslrCompatibilityChecker)
    end
  end

  describe "#compatible?" do
    context "when both states select same tokens" do
      it "returns true" do
        scanner_accepts = instance_double(Lrama::State::ScannerAccepts)
        allow(scanner_accepts).to receive(:[]).and_return(rangle)

        checker = Lrama::State::PslrCompatibilityChecker.new(
          scanner_accepts,
          length_prec
        )

        state1 = instance_double(Lrama::State, id: 0)
        state2 = instance_double(Lrama::State, id: 1)

        expect(checker.compatible?(state1, state2, scanner_fsa)).to be true
      end
    end

    context "when both states have no tokens (nil)" do
      it "returns true" do
        scanner_accepts = instance_double(Lrama::State::ScannerAccepts)
        allow(scanner_accepts).to receive(:[]).and_return(nil)

        checker = Lrama::State::PslrCompatibilityChecker.new(
          scanner_accepts,
          length_prec
        )

        state1 = instance_double(Lrama::State, id: 0)
        state2 = instance_double(Lrama::State, id: 1)

        expect(checker.compatible?(state1, state2, scanner_fsa)).to be true
      end
    end

    context "when states select different tokens" do
      it "returns false" do
        scanner_accepts = instance_double(Lrama::State::ScannerAccepts)

        # State 0 selects RANGLE, State 1 selects RSHIFT
        allow(scanner_accepts).to receive(:[]) do |state_id, _fsa_state_id|
          if state_id == 0
            rangle
          else
            rshift
          end
        end

        checker = Lrama::State::PslrCompatibilityChecker.new(
          scanner_accepts,
          length_prec
        )

        state1 = instance_double(Lrama::State, id: 0)
        state2 = instance_double(Lrama::State, id: 1)

        expect(checker.compatible?(state1, state2, scanner_fsa)).to be false
      end
    end
  end
end
