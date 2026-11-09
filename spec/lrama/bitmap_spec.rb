# frozen_string_literal: true

RSpec.describe Lrama::Bitmap do
  describe ".from_array" do
    it "converts array of integer into bitmap integer" do
      expect(Lrama::Bitmap.from_array([])).to eq(0b0)
      expect(Lrama::Bitmap.from_array([0])).to eq(0b1)
      expect(Lrama::Bitmap.from_array([1])).to eq(0b10)
      expect(Lrama::Bitmap.from_array([2, 3])).to eq(0b1100)
      expect(Lrama::Bitmap.from_array([6, 4])).to eq(0b1010000)
    end
  end

  describe ".from_integer" do
    it "converts integer into bitmap integer" do
      expect(Lrama::Bitmap.from_integer(0)).to eq(0b1)
      expect(Lrama::Bitmap.from_integer(1)).to eq(0b10)
      expect(Lrama::Bitmap.from_integer(2)).to eq(0b100)
      expect(Lrama::Bitmap.from_integer(3)).to eq(0b1000)
      expect(Lrama::Bitmap.from_integer(4)).to eq(0b10000)
      expect(Lrama::Bitmap.from_integer(5)).to eq(0b100000)
      expect(Lrama::Bitmap.from_integer(6)).to eq(0b1000000)
    end
  end

  describe ".to_array" do
    it "converts bitmap integer into array of integer" do
      expect(Lrama::Bitmap.to_array(0b0)).to eq([])
      expect(Lrama::Bitmap.to_array(0b1)).to eq([0])
      expect(Lrama::Bitmap.to_array(0b10)).to eq([1])
      expect(Lrama::Bitmap.to_array(0b1100)).to eq([2, 3])
      expect(Lrama::Bitmap.to_array(0b1010000)).to eq([4, 6])
    end

    it "returns sparse bits in ascending order across integer word boundaries" do
      positions = [4096, 127, 64, 63, 62, 1, 0]
      bitmap = Lrama::Bitmap.from_array(positions)

      expect(Lrama::Bitmap.to_array(bitmap)).to eq(positions.sort)
    end

    it "returns every bit in a dense bitmap" do
      expect(Lrama::Bitmap.to_array((1 << 256) - 1)).to eq((0...256).to_a)
    end
  end

  describe '.any?' do
    it 'returns false without yielding for an empty bitmap' do
      expect(described_class.any?(0) { raise 'unexpected bit' }).to be(false)
    end

    it 'stops at the first matching bit across integer word boundaries' do
      visited = []
      result = described_class.any?((1 << 130) | (1 << 64) | 1) do |index|
        visited << index
        index == 64
      end

      expect(result).to be(true)
      expect(visited).to eq([0, 64])
    end

    it 'returns false after testing every set bit when none match' do
      visited = []
      result = described_class.any?((1 << 130) | 1) do |index|
        visited << index
        index == 129
      end

      expect(result).to be(false)
      expect(visited).to eq([0, 130])
    end
  end

  describe '.to_bool_array' do
    it 'converts bitmap integer into array of boolean' do
      expect(Lrama::Bitmap.to_bool_array(0b0, 1)).to eq([false])
      expect(Lrama::Bitmap.to_bool_array(0b1, 1)).to eq([true])
      expect(Lrama::Bitmap.to_bool_array(0b1, 2)).to eq([true, false])
      expect(Lrama::Bitmap.to_bool_array(0b10, 2)).to eq([false, true])
      expect(Lrama::Bitmap.to_bool_array(0b1100, 4)).to eq([false, false, true, true])
      expect(Lrama::Bitmap.to_bool_array(0b1100, 7)).to eq([false, false, true, true, false, false, false])
      expect(Lrama::Bitmap.to_bool_array(0b1010000, 7)).to eq([false, false, false, false, true, false, true])
    end
  end
end
