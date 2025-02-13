# frozen_string_literal: true

RSpec.describe Lrama::Warnings::Required do
  describe "#warn" do
    let(:y) do
      <<~STR
        %require "3.0"
        %{
        // Prologue
        %}
        %union {
            int i;
        }
        %token <i> tNUMBER
        %%
        program: tNUMBER
                ;
      STR
    end

    context "when warnings true" do
      it "has warns for require is provided for compatibility with bison" do
        grammar = Lrama::Parser.new(y, "states/required.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = Lrama::Logger.new
        allow(logger).to receive(:warn)
        Lrama::Warnings.new(logger, true).warn(grammar, states)
        expect(logger).to have_received(:warn).with("%require is provided for compatibility with bison and can be removed after migration to lrama")
      end
    end

    context "when warnings false" do
      it "has not warns for require is provided for compatibility with bison" do
        grammar = Lrama::Parser.new(y, "states/required.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = Lrama::Logger.new
        allow(logger).to receive(:warn)
        Lrama::Warnings.new(logger, false).warn(grammar, states)
        expect(logger).not_to have_received(:warn).with("%require is provided for compatibility with bison and can be removed after migration to lrama")
      end
    end
  end
end
