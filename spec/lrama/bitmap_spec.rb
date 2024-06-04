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

  describe ".to_array" do
    it "converts bitmap integer into array of integer" do
      expect(Lrama::Bitmap.to_array(0b0)).to eq([])
      expect(Lrama::Bitmap.to_array(0b1)).to eq([0])
      expect(Lrama::Bitmap.to_array(0b10)).to eq([1])
      expect(Lrama::Bitmap.to_array(0b1100)).to eq([2, 3])
      expect(Lrama::Bitmap.to_array(0b1010000)).to eq([4, 6])
    end
  end
end
