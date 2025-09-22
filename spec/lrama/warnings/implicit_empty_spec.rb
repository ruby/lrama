# frozen_string_literal: true

RSpec.describe Lrama::Warnings::ImplicitEmpty do
  describe "#warn" do
    let(:y) do
      <<~STR
        %{
        // Prologue
        %}
        %union {
            int i;
        }
        %token <i> tNUMBER
        %%
        program: /* empty */
                | tNUMBER
                ;
      STR
    end

    context "when warnings true" do
      it "has warns for parameterized rule redefined" do
        grammar = Lrama::Parser.new(y, "states/empty.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = Lrama::Logger.new
        allow(logger).to receive(:warn)
        Lrama::Warnings.new(logger, true).warn(grammar, states)
        expect(logger).to have_received(:warn).with("warning: empty rule without %empty")
      end
    end

    context "when warnings false" do
      it "has not warns for parameterized rule redefined" do
        grammar = Lrama::Parser.new(y, "states/empty.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = Lrama::Logger.new
        allow(logger).to receive(:warn)
        Lrama::Warnings.new(logger, false).warn(grammar, states)
        expect(logger).not_to have_received(:warn).with("warning: empty rule without %empty")
      end
    end
  end
end
