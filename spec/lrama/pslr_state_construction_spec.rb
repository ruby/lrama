# frozen_string_literal: true

RSpec.describe Lrama::States, "PSLR state construction" do
  let(:source) do
    <<~GRAMMAR
      %define lr.type pslr
      %token P Q Z X
      %lexer-context BEG P
      %lexer-context CMDARG Q
      %%
      start: P n | Q n;
      n: Z X | Z n;
    GRAMMAR
  end

  def states_for(source, define = {})
    grammar = Lrama::Parser.new(source, "states/pslr.y", false, false, define).parse
    grammar.prepare
    grammar.validate!
    described_class.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
  end

  def transition(states, from, symbol)
    from.transitions_by_symbol_number.fetch(states.find_symbol_by_s_value!(symbol).number).to_state
  end

  it "preserves both predecessor contexts through neutral shifts and cycles" do
    states = states_for(source)
    states.compute
    states.compute_pslr

    start = states.states.first
    %w[P Q].zip([1, 2]).each do |name, context|
      state = transition(states, start, name)
      %w[Z Z X].each do |neutral|
        state = transition(states, state, neutral)
        expect(states.lexer_context_table[state.id]).to eq(context)
      end
    end
  end

  it "keeps predecessors consistent with the final context-specific transitions" do
    states = states_for(source)
    states.compute
    states.compute_pslr
    states.states.each do |target|
      incoming = states.states.select { |s| s.transitions.any? { |t| t.to_state.equal?(target) } }
      expect(target.predecessors.map(&:id)).to match_array(incoming.map(&:id))
    end
  end

  it "uses an explicit context on a transition in preference to an inherited one" do
    states = states_for(source.sub("%%", "%lexer-context END Z\n%%"))
    states.compute
    states.compute_pslr
    targets = states.states.select { |s| s.accessing_symbol == states.find_symbol_by_s_value!("Z") }
    expect(targets.map(&:lexer_context)).to eq([4])
  end

  [
    ["empty: %empty %prec HIGH; direct: A %prec OP;", true],
    ["direct: A %prec OP; empty: %empty %prec HIGH;", false],
  ].each do |rules, accepts_op|
    it "matches the parse table when competing reductions appear as #{rules}" do
      states = states_for(<<~GRAMMAR)
        %define lr.type pslr
        %token A OP X Y Z
        %nonassoc OP
        %precedence HIGH
        %%
        start: A empty OP X | direct OP Y | A OP Z;
        #{rules}
      GRAMMAR
      states.compute
      states.compute_pslr
      state = states.states.find { |candidate| candidate.reduces.size == 2 }
      expect(states.pslr_acceptable_tokens(state).include?("OP")).to be(accepts_op)
      incoming = state.item_lookahead_set
      tokens = Lrama::State::ScannerAccepts.acceptable_tokens(state, states.symbols, incoming)
      expect(tokens.include?("OP")).to be(accepts_op)
    end
  end

  describe "state limits" do
    before do
      allow(Lrama::State).to receive(:new).and_call_original
    end

    it "stops constructing LR(0) states at the absolute limit" do
      states = states_for(source, "pslr.max-states" => "5")
      expect(Lrama::State).not_to receive(:new).with(5, anything, anything)
      expect { states.compute }.to raise_error(/PSLR state growth exceeded pslr.max-states=5/)
      expect(states.states_count).to eq(5)
    end

    it "checks the absolute limit before allocating a scanner-driven split" do
      grammar = File.read(fixture_path("command/pslr_growth_limit.y"))
      states = states_for(grammar, "pslr.max-states" => "15")
      states.compute
      expect(states.states_count).to eq(14)
      expect(Lrama::State).not_to receive(:new).with(15, anything, anything)
      expect { states.compute_pslr }.to raise_error(/PSLR state growth exceeded pslr.max-states=15/)
      expect(states.states_count).to eq(15)
    end

    it "checks the ratio before allocating a lexer-context split" do
      states = states_for(source, "pslr.max-state-ratio" => "1.0")
      states.compute
      base = states.states_count
      expect(Lrama::State).not_to receive(:new).with(base, anything, anything)
      expect { states.compute_pslr }.to raise_error(/PSLR state growth exceeded pslr.max-state-ratio=1.0/)
      expect(states.states_count).to eq(base)
    end
  end
end
