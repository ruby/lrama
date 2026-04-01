# frozen_string_literal: true

require "stringio"

RSpec.describe "counterexamples output" do
  let(:grammar_source) do
    <<~Y
      %token ID ','

      %%

      s: a ID
       ;

      a: expr
       ;

      expr: %empty
          | expr ID ','
          ;
    Y
  end

  let(:grammar) do
    grammar = Lrama::Parser.new(grammar_source, "ids.y").parse
    grammar.prepare
    grammar.validate!
    grammar
  end

  let(:states) do
    states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
    states.compute
    states
  end

  describe "warning output" do
    it "suggests rerunning with -Wcounterexamples when conflicts exist" do
      io = StringIO.new
      logger = Lrama::Logger.new(io)

      Lrama::Warnings.new(logger, true, {}).warn(grammar, states)

      expect(io.string).to include("warning: shift/reduce conflicts: 1 found\n")
      expect(io.string).to include("note: rerun with option '-Wcounterexamples' to generate conflict counterexamples\n")
    end

    it "renders nonunifying counterexamples with first and second examples" do
      io = StringIO.new
      logger = Lrama::Logger.new(io)

      Lrama::Warnings.new(logger, true, { counterexamples: true }).warn(grammar, states)

      expect(io.string).to include("warning: shift/reduce conflict on token ID [-Wcounterexamples]\n")
      expect(io.string).to include("  First example: expr • ID ',' ID $end\n")
      expect(io.string).to include("  Second example: expr • ID $end\n")
      expect(io.string).to include("  Shift derivation\n")
      expect(io.string).to include("  Reduce derivation\n")
    end
  end

  describe "report output" do
    it "renders counterexample example lines inside the state report" do
      io = StringIO.new

      Lrama::Reporter.new(states: true, counterexamples: true).report(io, states)

      expect(io.string).to include("shift/reduce conflict on token ID:\n")
      expect(io.string).to include("      First example: expr • ID ',' ID $end\n")
      expect(io.string).to include("      Second example: expr • ID $end\n")
      expect(io.string).to include("      Shift derivation\n")
      expect(io.string).to include("      Reduce derivation\n")
    end

    it "collapses ambiguous arithmetic conflicts to a shared example" do
      grammar = Lrama::Parser.new(<<~Y, "calc.y").parse
        %token NUM
        %%
        exp:
          exp '+' exp
        | exp '-' exp
        | exp '*' exp
        | exp '/' exp
        | NUM
        ;
      Y
      grammar.prepare
      grammar.validate!

      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute

      io = StringIO.new
      Lrama::Reporter.new(states: true, counterexamples: true).report(io, states)

      expect(io.string).to include("shift/reduce conflict on token '/':\n")
      expect(io.string).to include("      Example: exp '+' exp • '/' exp\n")
      expect(io.string).not_to include("      First example: exp '+' exp • '/' exp\n")
      expect(io.string).not_to include("      Second example: exp '+' exp • '/' exp\n")
    end

    it "keeps separate reduce/reduce counterexamples when the lookahead changes the witness" do
      grammar = Lrama::Parser.new(<<~Y, "multi_rr.y").parse
        %token X Y
        %%
        s: p q ;
        p: a | b ;
        a: %empty ;
        b: %empty ;
        q: x | y ;
        x: X ;
        y: Y ;
      Y
      grammar.prepare
      grammar.validate!

      states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute

      io = StringIO.new
      Lrama::Reporter.new(states: true, counterexamples: true).report(io, states)

      expect(io.string).to include("    reduce/reduce conflict on token X:\n")
      expect(io.string).to include("      Example: • • X $end\n")
      expect(io.string).to include("    reduce/reduce conflict on token Y:\n")
      expect(io.string).to include("      Example: • • Y $end\n")
      expect(io.string).not_to include("    reduce/reduce conflict on tokens X, Y:\n")
    end
  end
end
