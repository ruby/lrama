# frozen_string_literal: true

require_relative "grammar"

RSpec.describe IELRGrammar do
  it "reproduces a grammar independently of other seeds" do
    grammar = described_class.generate(79)
    described_class.generate(29)

    expect(described_class.generate(79)).to eq(grammar)
    expect(described_class.generate(213)).not_to eq(grammar)
  end

  it "generates IELR grammars with productive nonterminals and precedence" do
    grammars = 10.times.map { |seed| described_class.generate(seed) }

    grammars.each do |source|
      grammar = Lrama::Parser.new(source, "random.y").parse
      grammar.prepare
      grammar.validate!
      expect(source).to include("%define lr.type ielr")
      expect(source).to match(/^%token t0 t1 t2 t3 t4$/)
      7.times { |index| expect(source).to match(/^n#{index}: t[0-4]/) }
    end

    %w[%left %right %nonassoc %precedence %prec].each do |directive|
      expect(grammars.join).to include("#{directive} ")
    end
  end

  [22, 108, 155].each do |seed|
    it "reproduces the saved grammar for seed #{seed}" do
      path = fixture_path("ielr/seed_#{seed}.y")
      expect(File).to exist(path)
      expect(described_class.generate(seed)).to eq(File.read(path).gsub("\r\n", "\n"))
    end
  end

  [108, 155].each do |seed|
    it "exercises IELR state splitting with seed #{seed}" do
      grammar = Lrama::Parser.new(File.read(fixture_path("ielr/seed_#{seed}.y")), "seed_#{seed}.y").parse
      grammar.prepare
      states = Lrama::States.new(grammar, Lrama::Tracer.new(StringIO.new))
      states.compute
      lalr_count = states.states.length
      states.compute_ielr

      expect(states.states.length).to be > lalr_count
    end
  end

  it "propagates merged annotations through a cycle without unnecessary state splitting" do
    path = fixture_path("ielr/annotation_cycle.y")
    grammar = Lrama::Parser.new(File.read(path), path).parse
    grammar.prepare
    states = Lrama::States.new(grammar, Lrama::Tracer.new(StringIO.new))
    states.compute
    expect(states.states.length).to eq(7)

    states.compute_ielr

    expect(states.states.length).to eq(7)
    expect(states.sr_conflicts_count).to eq(1)
    expect(states.rr_conflicts_count).to eq(0)
  end

  it "preserves always contributions without splitting equivalent states" do
    path = fixture_path("ielr/always_contributions.y")
    grammar = Lrama::Parser.new(File.read(path), path).parse
    grammar.prepare
    states = Lrama::States.new(grammar, Lrama::Tracer.new(StringIO.new))
    states.compute
    expect(states.states.length).to eq(15)

    states.compute_ielr

    expect(states.states.length).to eq(15)
    expect(states.sr_conflicts_count).to eq(4)
    expect(states.rr_conflicts_count).to eq(1)
    expect { Lrama::Context.new(states) }.not_to raise_error
  end

  it "builds parser tables for seed 22" do
    grammar = Lrama::Parser.new(File.read(fixture_path("ielr/seed_22.y")), "seed_22.y").parse
    grammar.prepare
    states = Lrama::States.new(grammar, Lrama::Tracer.new(StringIO.new))
    states.compute
    states.compute_ielr

    pending "Context#compute_yydefact calls each on a nil reduce lookahead"
    expect { Lrama::Context.new(states) }.not_to raise_error
  end
end
