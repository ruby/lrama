# frozen_string_literal: true

RSpec.describe Lrama::Grammar::Rule do
  describe '#==' do
    it 'distinguishes otherwise identical rules by ID' do
      first = described_class.new(id: 1, rhs: [], lineno: 3)
      second = described_class.new(id: 2, rhs: [], lineno: 3)

      expect(first).not_to eq(second)
    end
  end
end
