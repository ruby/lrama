# frozen_string_literal: true

RSpec.describe Lrama::OrderedSet do
  describe "#shift" do
    context "if the set is empty" do
      it "returns nil" do
        set = Lrama::OrderedSet.new
        expect(set.shift).to be nil
      end
    end

    context "if the set is not empty" do
      it "returns the first object and discard it" do
        set = Lrama::OrderedSet.new
        set << 1
        set << 2

        expect(set.shift).to be 1
        expect(set.shift).to be 2
      end
    end
  end

  describe "#<<" do
    context "if the set doesn't have the appended object" do
      it "appends the object and returns true" do
        set = Lrama::OrderedSet.new
        set << 1

        expect(set << 2).to be true
        expect(set.to_a).to eq [1, 2]
      end
    end

    context "if the set has the appended object" do
      it "doesn't append the object and returns false" do
        set = Lrama::OrderedSet.new

        set << 1
        set << 2
        expect(set << 1).to be false
        expect(set.to_a).to eq [1, 2]
      end
    end
  end
end
