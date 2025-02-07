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
