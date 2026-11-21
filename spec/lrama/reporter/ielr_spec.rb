# frozen_string_literal: true

RSpec.describe Lrama::Reporter::Ielr do
  def report_for(source, path = "ielr_report.y")
    grammar = Lrama::Parser.new(source, path).parse
    grammar.prepare
    grammar.validate!
    states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
    states.compute
    states.compute_ielr

    io = StringIO.new
    described_class.new(ielr: true).report(io, states)
    io.string
  end

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

      expect(report_for(y)).to eq(<<~STR)
        IELR Isocores

            Isocore of LALR state 5: IELR states 5, 15

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
                token a (conflict in LALR state 5)
                  state 5 [LALR core]: reduce using rule 6 (A1)
                  state 15 [IELR split]: reduce using rule 7 (A2)
                token b (conflict in LALR state 5)
                  state 5 [LALR core]: reduce using rule 7 (A2)
                  state 15 [IELR split]: reduce using rule 6 (A1)


      STR
    end

    it "reports dominant contributions at the state where the conflict originated" do
      path = fixture_path("integration/ielr.y")
      expect(report_for(File.read(path), path)).to include(<<~STR.chomp)
        Why it split
                token a (conflict in LALR state 14)
                  state 4 [LALR core]: reduce using rule 9 (E)
                  state 19 [IELR split]: shift and go to state 17
      STR
    end

    it "omits a token when only one isocore contributes to its conflict" do
      report = report_for(<<~GRAMMAR)
        %define lr.type ielr
        %%
        s: 'p' x 'a' | 'p' y 'b' | 'q' x 'b' | 'q' y 'a' | 'p' x 'c' | 'p' y 'c';
        x: 'z';
        y: 'z';
      GRAMMAR
      expect(report.scan(/token ('\w+')/).flatten).to eq(["'a'", "'b'"])
    end

    it "reports a nonassociative syntax error as a distinct contribution" do
      report = report_for(<<~GRAMMAR)
        %define lr.type ielr
        %nonassoc 'a'
        %%
        s: 'p' x 'a' | 'q' x 'b' | 'p' z 'b' | 'q' z 'a';
        x: 'z' %prec 'a';
        z: 'z' 'a';
      GRAMMAR

      expect(report).to include(<<~STR.chomp)
        Why it split
                token 'a' (conflict in LALR state 4)
                  state 4 [LALR core]: syntax error
                  state 15 [IELR split]: shift and go to state 10
      STR
    end
  end
end
