# frozen_string_literal: true

RSpec.describe Lrama::Reporter::Ielr do
  describe "#report" do
    it "reports LALR vs IELR split diagnostics" do
      y = <<~INPUT
        %{
        // Prologue
        %}

        %define lr.type ielr

        %token a
        %token b
        %token c

        %%

        S: S2
         ;

        S2: a A1 a
          | a A2 b
          | b A1 b
          | b A2 a
          ;

        A1: c
         ;

        A2: c
         ;

        %%
      INPUT

      grammar = Lrama::Parser.new(y, "ielr_diff.y").parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      states.compute_ielr

      io = StringIO.new
      described_class.new(ielr: true).report(io, states)

      expect(io.string).to eq(<<~STR)
        IELR State Splits

            LALR state 5 splits into IELR states 5, 15

              Incoming transitions
                state 1 -- c --> state 5 [LALR core]
                state 2 -- c --> state 15 [IELR split]

              Lookahead differences
                c •  (rule 6)
                  state 5 [LALR core]: [a]
                  state 15 [IELR split]: [b]
                c •  (rule 7)
                  state 5 [LALR core]: [b]
                  state 15 [IELR split]: [a]

              Why it split
                token a
                  state 5 [LALR core]: reduce using rule 6 (A1)
                  state 15 [IELR split]: reduce using rule 7 (A2)
                token b
                  state 5 [LALR core]: reduce using rule 7 (A2)
                  state 15 [IELR split]: reduce using rule 6 (A1)


      STR
    end

    it "reports shift destinations from the current split state" do
      grammar = Lrama::Parser.new(File.read(fixture_path("integration/ielr.y")), fixture_path("integration/ielr.y")).parse
      grammar.prepare
      grammar.validate!
      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      states.compute_ielr

      io = StringIO.new
      described_class.new(ielr: true).report(io, states)

      expect(io.string).to include("state 19 [IELR split]: shift and go to state 8")
      expect(io.string).to include("state 20 [IELR split]: shift and go to state 8")
      expect(io.string).to include("state 21 [IELR split]: shift and go to state 17")
      expect(io.string).not_to include("state 19 [IELR split]: shift and go to state 17")
      expect(io.string).not_to include("state 20 [IELR split]: shift and go to state 17")
    end
  end
end
