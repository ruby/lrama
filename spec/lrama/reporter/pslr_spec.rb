# frozen_string_literal: true

require "stringio"

RSpec.describe Lrama::Reporter::Pslr do
  def build_states(source)
    grammar = Lrama::Parser.new(source, "reporter_pslr.y").parse
    grammar.prepare
    grammar.validate!
    states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
    states.compute
    states.compute_pslr
    states
  end

  let(:source) do
    <<~GRAMMAR
      %define lr.type pslr
      %token-pattern RSHIFT />>/
      %token-pattern RANGLE />/
      %token-pattern USELESS_A /a/
      %token-pattern USELESS_B /b/
      %lex-prec RANGLE -s RSHIFT
      %lex-prec USELESS_A -~ USELESS_B
      %%
      program: RSHIFT | RANGLE
    GRAMMAR
  end

  it "reports summary, accept sets, scanner accepts rows and useless rules" do
    states = build_states(source)
    io = StringIO.new
    described_class.new(pslr: true).report(io, states)
    output = io.string

    expect(output).to include("PSLR Summary")
    expect(output).to include("PSLR Acceptable Tokens")
    expect(output).to include("PSLR Scanner Accepts")
    expect(output).to include("Fallback:")
    expect(output).to include("PSLR Useless %lex-prec Rules")
    expect(output).to include("USELESS_A -~ USELESS_B")
  end

  it "reports nothing for non-PSLR grammars" do
    grammar = Lrama::Parser.new("%token NUM\n%%\nprogram: NUM\n", "plain.y").parse
    grammar.prepare
    grammar.validate!
    states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
    states.compute
    io = StringIO.new
    described_class.new(pslr: true).report(io, states)

    expect(io.string).to eq("")
  end
end
