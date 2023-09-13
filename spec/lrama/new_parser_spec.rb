RSpec.describe Lrama::NewParser do
  describe '#parse' do
    subject { described_class.new(grammar).parse }

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
      expect(subject).to eq(expected)
    end
  end
end
