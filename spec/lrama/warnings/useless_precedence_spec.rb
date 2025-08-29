# frozen_string_literal: true

RSpec.describe Lrama::Warnings::UselessPrecedence do
  describe "#warn" do
    context "when warnings true" do
      context "when precedences are used" do
        it "has not warns for unused precedences" do
          path = "states/precedence_used.y"
          y = File.read(fixture_path(path))
          grammar = Lrama::Parser.new(y, "states/precedence_used.y").parse
          grammar.prepare
          grammar.validate!
          states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
          states.compute
          logger = Lrama::Logger.new
          allow(logger).to receive(:warn)
          Lrama::Warnings.new(logger, true).warn(grammar, states)
          expect(logger).not_to have_received(:warn)
        end
      end

      context "when precedences are unused" do
        it "has warns for unused precedences" do
          path = "states/precedence_unused.y"
          y = File.read(fixture_path(path))
          grammar = Lrama::Parser.new(y, "states/precedence_unused.y").parse
          grammar.prepare
          grammar.validate!
          states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
          states.compute
          logger = Lrama::Logger.new
          allow(logger).to receive(:warn)
          Lrama::Warnings.new(logger, true).warn(grammar, states)
          expect(logger).to have_received(:warn).with("Precedence PRECEDENCE (line: 14) is defined but not used in any rule.").once
        end
      end

      context "when precedences are defined but not used in any rule" do
        it "has warns for unused precedences" do
          path = "states/precedence_without_prec.y"
          y = File.read(fixture_path(path))
          grammar = Lrama::Parser.new(y, "states/precedence_without_prec.y").parse
          grammar.prepare
          grammar.validate!
          states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
          states.compute
          logger = Lrama::Logger.new
          allow(logger).to receive(:warn)
          Lrama::Warnings.new(logger, true).warn(grammar, states)
          expect(logger).to have_received(:warn).with("Precedence PRECEDENCE (line: 14) is defined but not used in any rule.").once
        end
      end
    end

    context "when warnings false" do
      it "has not warns for unused precedences" do
        path = "states/precedence_unused.y"
        y = File.read(fixture_path(path))
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
