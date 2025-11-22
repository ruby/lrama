# frozen_string_literal: true

RSpec.describe Lrama::Warnings::NameConflicts do
  describe "#warn" do
    context "when parameterized rule name conflicts with terminal symbol" do
      let(:y) do
        <<~STR
          %{
          // Prologue
          %}
          %union {
              int i;
          }
          %token <i> option tNUMBER
          %rule option(X) : /* empty */
                          | X
                          ;
          %%
          program: option(tNUMBER)
                 ;
        STR
      end

      context "when warnings true" do
        it "warns about the conflict" do
          grammar = Lrama::Parser.new(y, "name_conflicts/term_conflict.y").parse
          grammar.prepare
          grammar.validate!
          states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
          states.compute
          logger = Lrama::Logger.new
          allow(logger).to receive(:warn)
          Lrama::Warnings.new(logger, true).warn(grammar, states)
          expect(logger).to have_received(:warn).with('warning: parameterized rule name "option" conflicts with symbol name')
        end
      end

      context "when warnings false" do
        it "does not warn" do
          grammar = Lrama::Parser.new(y, "name_conflicts/term_conflict.y").parse
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

    context "when parameterized rule name conflicts with non-terminal symbol" do
      let(:y) do
        <<~STR
          %{
          // Prologue
          %}
          %union {
              int i;
          }
          %token <i> tNUMBER
          %rule program(X) : X
                           ;
          %%
          program: tNUMBER
                 ;
        STR
      end

      context "when warnings true" do
        it "warns about the conflict" do
          grammar = Lrama::Parser.new(y, "name_conflicts/nterm_conflict.y").parse
          grammar.prepare
          grammar.validate!
          states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
          states.compute
          logger = Lrama::Logger.new
          allow(logger).to receive(:warn)
          Lrama::Warnings.new(logger, true).warn(grammar, states)
          expect(logger).to have_received(:warn).with('warning: parameterized rule name "program" conflicts with symbol name')
        end
      end

      context "when warnings false" do
        it "does not warn" do
          grammar = Lrama::Parser.new(y, "name_conflicts/nterm_conflict.y").parse
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

    context "when there are no conflicts" do
      let(:y) do
        <<~STR
          %{
          // Prologue
          %}
          %union {
              int i;
          }
          %token <i> tNUMBER
          %rule my_option(X) : /* empty */
                             | X
                             ;
          %%
          program: my_option(tNUMBER)
                 ;
        STR
      end

      context "when warnings true" do
        it "does not warn" do
          grammar = Lrama::Parser.new(y, "name_conflicts/no_conflict.y").parse
          grammar.prepare
          grammar.validate!
          states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
          states.compute
          logger = Lrama::Logger.new
          allow(logger).to receive(:warn)
          Lrama::Warnings.new(logger, true).warn(grammar, states)
          expect(logger).not_to have_received(:warn).with(/parameterized rule name.*conflicts/)
        end
      end
    end

    context "when there are no parameterized rules" do
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
          program: tNUMBER
                 ;
        STR
      end

      context "when warnings true" do
        it "does not warn" do
          grammar = Lrama::Parser.new(y, "name_conflicts/no_param_rules.y").parse
          grammar.prepare
          grammar.validate!
          states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
          states.compute
          logger = Lrama::Logger.new
          allow(logger).to receive(:warn)
          Lrama::Warnings.new(logger, true).warn(grammar, states)
          expect(logger).not_to have_received(:warn).with(/parameterized rule name.*conflicts/)
        end
      end
    end

    context "when multiple parameterized rules have conflicts" do
      let(:y) do
        <<~STR
          %{
          // Prologue
          %}
          %union {
              int i;
          }
          %token <i> option separated tNUMBER
          %rule option(X) : /* empty */
                          | X
                          ;
          %rule separated(X, Y) : X Y
                                ;
          %%
          program: option(tNUMBER) separated(tNUMBER, tNUMBER)
                 ;
        STR
      end

      context "when warnings true" do
        it "warns about all conflicts" do
          grammar = Lrama::Parser.new(y, "name_conflicts/multiple_conflicts.y").parse
          grammar.prepare
          grammar.validate!
          states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
          states.compute
          logger = Lrama::Logger.new
          allow(logger).to receive(:warn)
          Lrama::Warnings.new(logger, true).warn(grammar, states)
          expect(logger).to have_received(:warn).with('warning: parameterized rule name "option" conflicts with symbol name')
          expect(logger).to have_received(:warn).with('warning: parameterized rule name "separated" conflicts with symbol name')
        end
      end
    end
  end
end
