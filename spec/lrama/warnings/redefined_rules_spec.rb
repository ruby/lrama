# frozen_string_literal: true

RSpec.describe Lrama::Warnings::RedefinedRules do
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
        %rule foo(X) : X
                        ;
        %rule foo(Y) : Y
                        ;
        %%
        program: foo(tNUMBER)
                ;
      STR
    end

    context "when warnings true" do
      it "has warns for parameterizing rule redefined" do
        grammar = Lrama::Parser.new(y, "states/parameterizing_rule_redefined.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = Lrama::Logger.new
        allow(logger).to receive(:warn)
        Lrama::Warnings.new(logger, true).warn(grammar, states)
        expect(logger).to have_received(:warn).with("parameterizing rule redefined: foo(X)")
        expect(logger).to have_received(:warn).with("parameterizing rule redefined: foo(Y)")
      end
    end

    context "when warnings false" do
      it "has not warns for parameterizing rule redefined" do
        grammar = Lrama::Parser.new(y, "states/parameterizing_rule_redefined.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = Lrama::Logger.new
        allow(logger).to receive(:warn)
        Lrama::Warnings.new(logger, false).warn(grammar, states)
        expect(logger).not_to have_received(:warn).with("parameterizing rule redefined: foo(X)")
        expect(logger).not_to have_received(:warn).with("parameterizing rule redefined: foo(Y)")
      end
    end
  end
end
