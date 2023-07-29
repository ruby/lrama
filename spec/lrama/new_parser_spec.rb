RSpec.describe Lrama::NewParser do
  describe '#parse' do
    subject { described_class.new(grammar).parse }

    let(:grammar) { File.read('sample/calc.y') }

    it 'returns the same results as Lrama::Parser' do
      expected = Lrama::Parser.new(grammar).parse

      expect(subject).to eq(expected)
    end
  end
end
