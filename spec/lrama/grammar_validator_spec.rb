# frozen_string_literal: true

RSpec.describe Lrama::GrammarValidator do
  describe "#valid?" do
    let(:y) do
      <<~STR
        %union {
            int i;
            long l;
            char *str;
        }

        %token EOI 0 "EOI"
        %token <i> '\\'  "backslash"
        %token <i> '\13' "escaped vertical tab"
        %token <i> keyword_class
        %token <i> keyword_class2
        %token <l> tNUMBER
        %token <str> tSTRING
        %token <i> keyword_end "end"
        %token tPLUS  "+"
        %token tMINUS "-"
        %token tEQ    "="
        %token tEQEQ  "=="

        %type <i> class /* comment for class */

        %nonassoc tEQEQ
        %left  tPLUS tMINUS '>'
        %right tEQ

        %%

        program: class
               | '+' strings_1
               | '-' strings_2
               ;

        class : keyword_class tSTRING keyword_end %prec tPLUS
                  { code 1 }
              | keyword_class { code 2 } tSTRING '!' keyword_end { code 3 } %prec "="
              | keyword_class { code 4 } tSTRING '?' keyword_end { code 5 } %prec '>'
              ;

        strings_1: string_1
                 ;

        strings_2: string_1
                 | string_2
                 ;

        string_1: string
                ;

          string_2: string '+'
                  ;

          string: tSTRING
                ;

          %%
      STR
    end

    context "when expect is specified" do
      context "when the number of s/r conflicts is same with expect" do
        let(:header) do
          <<~STR
            %{
            // Prologue
            %}

            %expect 2
          STR
        end

        it "has errors for r/r conflicts" do
          grammar = Lrama::Parser.new(header + y, "states/check_conflicts.y").parse
          grammar.prepare
          grammar.validate!
          states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
          states.compute
          logger = Lrama::Logger.new
          allow(logger).to receive(:error)

          expect(Lrama::GrammarValidator.new(grammar, states, logger).valid?).to be(false)
          expect(logger).to have_received(:error).with("reduce/reduce conflicts: 1 found, 0 expected")
        end
      end

      context "when the number of s/r conflicts is not same with expect" do
        let(:header) do
          <<~STR
            %{
            // Prologue
            %}

            %expect 0
          STR
        end

        it "has errors for s/r conflicts and r/r conflicts" do
          grammar = Lrama::Parser.new(header + y, "states/check_conflicts.y").parse
          grammar.prepare
          grammar.validate!
          states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
          states.compute
          logger = Lrama::Logger.new
          allow(logger).to receive(:error)

          expect(Lrama::GrammarValidator.new(grammar, states, logger).valid?).to be(false)
          expect(logger).to have_received(:error).with("shift/reduce conflicts: 2 found, 0 expected")
          expect(logger).to have_received(:error).with("reduce/reduce conflicts: 1 found, 0 expected")
        end
      end
    end

    describe "expect is not specified" do
      let(:header) do
        <<~STR
          %{
          // Prologue
          %}
        STR
      end

      it "has warns for s/r conflicts and r/r conflicts" do
        grammar = Lrama::Parser.new(header + y, "states/check_conflicts.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = Lrama::Logger.new
        allow(logger).to receive(:error)

        expect(Lrama::GrammarValidator.new(grammar, states, logger).valid?).to be(true)
        expect(logger).not_to have_received(:error)
      end
    end
  end
end
