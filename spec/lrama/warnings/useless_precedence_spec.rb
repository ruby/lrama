# frozen_string_literal: true

RSpec.describe Lrama::Warnings::UselessPrecedence do
  describe "#warn" do
    let(:y) do
      <<~STR
        %{
        // Prologue
        %}
        %union {
            int i;
        }
        %left tSTRING
        %precedence tNUMBER
        %right tIDENTIFIER
        %nonassoc tOPERATOR
        %precedence tTOKEN
        %%
        program: tNUMBER
                ;
      STR
    end

    context "when warnings true" do
      it "has warns for unused precedences" do
        grammar = Lrama::Parser.new(y, "states/useless_precedence.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = Lrama::Logger.new
        allow(logger).to receive(:warn)
        Lrama::Warnings.new(logger, true).warn(grammar, states)
        expect(logger).to have_received(:warn).with("Precedence tSTRING (line: 7) is defined but not used in any rule.").once
        expect(logger).to have_received(:warn).with("Precedence tIDENTIFIER (line: 9) is defined but not used in any rule.").once
        expect(logger).to have_received(:warn).with("Precedence tOPERATOR (line: 10) is defined but not used in any rule.").once
        expect(logger).to have_received(:warn).with("Precedence tTOKEN (line: 11) is defined but not used in any rule.").once
      end
    end

    context "when warnings false" do
      it "has not warns for unused precedences" do
        grammar = Lrama::Parser.new(y, "states/useless_precedence.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = Lrama::Logger.new
        allow(logger).to receive(:warn)
        Lrama::Warnings.new(logger, false).warn(grammar, states)
        expect(logger).not_to have_received(:warn)
      end
    end
  end
end
