# frozen_string_literal: true

RSpec.describe Lrama::Tracer::Closure do
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
          Closure: input
            . program "EOI"  (rule 0)


          Closure: output
            . program "EOI"  (rule 0)
            . class  (rule 1)
            . '+' strings_1  (rule 2)
            . '-' strings_2  (rule 3)
            . keyword_class tSTRING "end"  (rule 4)
            . keyword_class $@1 tSTRING '!' "end" $@2  (rule 7)
            . keyword_class $@3 tSTRING '?' "end" $@4  (rule 10)


        RULES
      end
    end

    context "when closure: true" do
      it "prints the all rules" do
        expect do
          described_class.new(STDERR, closure: true).trace(states.states.first)
        end.to output(<<~RULES).to_stderr_from_any_process
          Closure: input
            . program "EOI"  (rule 0)


          Closure: output
            . program "EOI"  (rule 0)
            . class  (rule 1)
            . '+' strings_1  (rule 2)
            . '-' strings_2  (rule 3)
            . keyword_class tSTRING "end"  (rule 4)
            . keyword_class $@1 tSTRING '!' "end" $@2  (rule 7)
            . keyword_class $@3 tSTRING '?' "end" $@4  (rule 10)


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
end
