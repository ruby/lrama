# frozen_string_literal: true

RSpec.describe Lrama::Counterexamples::Node do
  describe ".to_a" do
    it "returns an array whose elements are same with the node" do
      node = Lrama::Counterexamples::Node.new(0, nil)
      node = Lrama::Counterexamples::Node.new(1, node)
      expect(Lrama::Counterexamples::Node.to_a(node)).to eq([1, 0])
    end
  end
end
