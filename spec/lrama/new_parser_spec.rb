RSpec.describe Lrama::NewParser do
  describe '#parse' do
    subject { described_class.new(grammar).parse }

    describe 'sample/calc.y' do
      let(:grammar) { File.read('sample/calc.y') }

      it 'returns the same results as Lrama::Parser' do
        expected = Lrama::Parser.new(grammar).parse

        expect(subject.aux.prologue_first_lineno).to eq(expected.aux.prologue_first_lineno)
        expect(subject.aux.prologue.strip).to eq(expected.aux.prologue.strip)
        expect(subject.union.code).to eq(expected.union.code)
        expect(subject.union.lineno).to eq(expected.union.lineno)
        expect(subject.union).to eq(expected.union)
        expect(subject.types).to eq(expected.types)
        subject.instance_variable_get(:@_rules).each_with_index {|rule, id| expect(rule).to eq(expected.instance_variable_get(:@_rules)[id]) }
        expect(subject.instance_variable_get(:@_rules)).to eq(expected.instance_variable_get(:@_rules))
        expect(subject.aux.epilogue_first_lineno).to eq(expected.aux.epilogue_first_lineno)
        expect(subject.aux.epilogue.strip).to eq(expected.aux.epilogue.strip)

        subject.rules.each_with_index {|rule, i| expect(rule).to eq(expected.rules[i]) }
      end
    end

    describe 'sample/ruby_parse.y' do
      let(:grammar) { File.read('sample/ruby_parse.y') }

      it 'returns the same results as Lrama::Parser' do
        expected = Lrama::Parser.new(grammar).parse

        expect(subject.aux.prologue_first_lineno).to eq(expected.aux.prologue_first_lineno)
        expect(subject.aux.prologue.strip).to eq(expected.aux.prologue.strip)
        expect(subject.union.code).to eq(expected.union.code)
        expect(subject.union.lineno).to eq(expected.union.lineno)
        expect(subject.union).to eq(expected.union)
        expect(subject.types).to eq(expected.types)
        subject.instance_variable_get(:@_rules).each_with_index {|rule, id| expect(rule[0..1]).to eq(expected.instance_variable_get(:@_rules)[id][0..1]) }
        expect(subject.instance_variable_get(:@_rules).map { _1[0..1] }).to eq(expected.instance_variable_get(:@_rules).map { _1[0..1] })
        expect(subject.aux.epilogue_first_lineno).to eq(expected.aux.epilogue_first_lineno)
        expect(subject.aux.epilogue.strip).to eq(expected.aux.epilogue.strip)

        subject.rules.each_with_index {|rule, i| expect(rule).to eq(expected.rules[i]) }
      end
    end
  end
end
