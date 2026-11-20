# frozen_string_literal: true

RSpec.describe Lrama::States do
  describe 'conflict counts' do
    cases = [
      ['multiple reductions on one shifted token', <<~GRAMMAR, 1, 1, 2, 1],
        start: 'a' 'b' | first 'b' | second 'b';
        first: 'a';
        second: 'a';
      GRAMMAR
      ['multiple shifted tokens', <<~GRAMMAR, 2, 0, 2, 0],
        start: 'a' 'b' | 'a' 'c' | first 'b' | first 'c';
        first: 'a';
      GRAMMAR
      ['multiple lookaheads for a reduction pair', <<~GRAMMAR, 0, 2, 0, 1],
        start: first 'b' | first 'c' | second 'b' | second 'c';
        first: 'a';
        second: 'a';
      GRAMMAR
      ['three reductions on one token', <<~GRAMMAR, 0, 2, 0, 3],
        start: first 'b' | second 'b' | third 'b';
        first: 'a';
        second: 'a';
        third: 'a';
      GRAMMAR
      ['partially overlapping reduction lookaheads', <<~GRAMMAR, 0, 4, 0, 3],
        start: first 'b' | first 'c' | first 'd'
             | second 'b' | second 'c' | second 'd' | third 'c';
        first: 'a';
        second: 'a';
        third: 'a';
      GRAMMAR
      ['duplicate rules at the same source location', <<~GRAMMAR, 0, 2, 0, 3],
        start: expr 'b';
        expr: 'a' | 'a' | 'a';
      GRAMMAR
      ['the same lookahead in different states', <<~GRAMMAR, 0, 2, 0, 2],
        start: first 'b' | second 'b';
        first: 'a' | 'c';
        second: 'a' | 'c';
      GRAMMAR
    ]

    [:lalr, :ielr].each do |lr_type|
      cases.each do |description, rules, sr_count, rr_count, sr_pairs, rr_pairs|
        it "counts #{description} in #{lr_type}" do
          grammar = Lrama::Parser.new("%define lr.type #{lr_type}\n%%\n#{rules}", 'conflict_counts.y').parse
          grammar.prepare
          states = described_class.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
          states.compute
          states.compute_ielr if lr_type == :ielr

          expect(states.sr_conflicts_count).to eq(sr_count)
          expect(states.rr_conflicts_count).to eq(rr_count)
          expect(states.states.sum { |state| state.sr_conflicts.count }).to eq(sr_pairs)
          expect(states.states.sum { |state| state.rr_conflicts.count }).to eq(rr_pairs)

          io = StringIO.new
          Lrama::Reporter::Conflicts.new.report(io, states)
          expect(io.string.scan(/(\d+) shift\/reduce/).flatten.map(&:to_i).sum).to eq(sr_count)
          expect(io.string.scan(/(\d+) reduce\/reduce/).flatten.map(&:to_i).sum).to eq(rr_count)

          logger = Lrama::Logger.new
          allow(logger).to receive(:warn)
          Lrama::Warnings::Conflicts.new(logger, true).warn(states)
          expect(logger).to have_received(:warn).with("shift/reduce conflicts: #{sr_count} found") if sr_count > 0
          expect(logger).to have_received(:warn).with("reduce/reduce conflicts: #{rr_count} found") if rr_count > 0
        end
      end
    end

    it 'does not retain counts queried before computation' do
      grammar = Lrama::Parser.new("%%\nstart: expr 'b' | 'a' 'b';\nexpr: 'a' | 'a';\n", 'conflict_counts.y').parse
      grammar.prepare
      states = described_class.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      expect(states.sr_conflicts_count).to eq(0)
      expect(states.rr_conflicts_count).to eq(0)

      states.compute

      expect(states.sr_conflicts_count).to eq(1)
      expect(states.rr_conflicts_count).to eq(1)
    end

    it 'reports the current counts after IELR removes LALR conflicts' do
      grammar = Lrama::Parser.new(<<~GRAMMAR, 'conflict_counts.y').parse
        %define lr.type ielr
        %expect 0
        %%
        start: 'a' first 'd' | 'b' first 'e' | 'a' second 'e' | 'b' second 'd';
        first: 'c';
        second: 'c';
      GRAMMAR
      grammar.prepare
      states = described_class.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      expect(states.rr_conflicts_count).to eq(2)

      states.compute_ielr

      expect(states.rr_conflicts_count).to eq(0)
      expect { states.validate!(Lrama::Logger.new) }.not_to raise_error
    end

    it 'uses lookahead counts in expected-conflict diagnostics' do
      grammar = Lrama::Parser.new(<<~GRAMMAR, 'conflict_counts.y').parse
        %expect 0
        %%
        start: 'a' 'b' | first 'b' | second 'b' | third 'b';
        first: 'a';
        second: 'a';
        third: 'a';
      GRAMMAR
      grammar.prepare
      states = described_class.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
      states.compute
      logger = Lrama::Logger.new
      allow(logger).to receive(:error)

      expect { states.validate!(logger) }.to raise_error(SystemExit)

      expect(logger).to have_received(:error).with('shift/reduce conflicts: 1 found, 0 expected')
      expect(logger).to have_received(:error).with('reduce/reduce conflicts: 2 found, 0 expected')
    end
  end
end
