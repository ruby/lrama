# frozen_string_literal: true

RSpec.describe Lrama::Trace::State do
  describe "#trace" do
    let(:path) { "common/basic.y" }
    let(:y) { File.read(fixture_path(path)) }
    let(:grammar) do
      grammar = Lrama::Parser.new(y, path).parse
      grammar.prepare
      grammar.validate!
      grammar
    end
    let(:states) do
      states = Lrama::States.new(grammar, Lrama::Tracer.new(STDERR))
      states.compute
      states
    end

    context "when automaton: true" do
      it "prints the all rules" do
        expect do
          described_class.new(STDERR, automaton: true).trace(states.states.first)
        end.to output(<<~RULES).to_stderr_from_any_process
          Processing state 0 (reached by "EOI")
        RULES
      end
    end

    context "when closure: true" do
      it "prints the all rules" do
        expect do
          described_class.new(STDERR, closure: true).trace(states.states.first)
        end.to output(<<~RULES).to_stderr_from_any_process
          Processing state 0 (reached by "EOI")
        RULES
      end
    end

    context "when automaton: false and closure: false" do
      it 'does not print anything' do
        expect do
          described_class.new(STDERR, state: false).trace(states.states.first)
        end.to_not output.to_stderr_from_any_process
      end
    end

    context 'when empty options' do
      it 'does not print anything' do
        expect do
          described_class.new(STDERR).trace(states.states.first)
        end.to_not output.to_stderr_from_any_process
      end
    end
  end

  describe "#trace_list_append" do
    let(:path) { "common/basic.y" }
    let(:y) { File.read(fixture_path(path)) }
    let(:grammar) do
      grammar = Lrama::Parser.new(y, path).parse
      grammar.prepare
      grammar.validate!
      grammar
    end
    let(:states) do
      states = Lrama::States.new(grammar, Lrama::Tracer.new(STDERR))
      states.compute
      states
    end

    context "when automaton: true" do
      it "prints the all rules" do
        expect do
          described_class.new(STDERR, automaton: true).trace_list_append(0, states.states.first)
        end.to output(<<~RULES).to_stderr_from_any_process
          state_list_append (state = 0, symbol = 0 ("EOI"))
        RULES
      end
    end

    context "when closure: true" do
      it "prints the all rules" do
        expect do
          described_class.new(STDERR, closure: true).trace_list_append(0, states.states.first)
        end.to output(<<~RULES).to_stderr_from_any_process
          state_list_append (state = 0, symbol = 0 ("EOI"))
        RULES
      end
    end

    context "when automaton: false and closure: false" do
      it 'does not print anything' do
        expect do
          described_class.new(STDERR, state: false).trace_list_append(0, states.states.first)
        end.to_not output.to_stderr_from_any_process
      end
    end

    context 'when empty options' do
      it 'does not print anything' do
        expect do
          described_class.new(STDERR).trace_list_append(0, states.states.first)
        end.to_not output.to_stderr_from_any_process
      end
    end
  end
end
