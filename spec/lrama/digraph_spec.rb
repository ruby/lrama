# frozen_string_literal: true

RSpec.describe Lrama::Digraph do
  describe "#compute" do
    it "handles an empty graph" do
      expect(described_class.new([], {}, {}).compute).to eq({})
    end

    it "propagates attributes through cycles and shared dependencies in traversal order" do
      nodes = [:a, :b, :c, :d, :e, :f, :g, :h]
      relation = { a: [:b, :d], b: [:c], c: [:a, :e], d: [:c, :f], e: [:f], f: [:e], h: [:b] }
      base = nodes.map { |node| [node, [node]] }.to_h

      expect(described_class.new(nodes, relation, base).compute).to eq(
        a: [:a, :b, :c, :e, :f, :d],
        b: [:a, :b, :c, :e, :f, :d],
        c: [:a, :b, :c, :e, :f, :d],
        d: [:a, :b, :c, :e, :f, :d],
        e: [:e, :f],
        f: [:e, :f],
        g: [:g],
        h: [:h, :a, :b, :c, :e, :f, :d]
      )
    end

    context "with a deep dependency graph" do
      let(:nodes) { (0...10_000).to_a }
      let(:relation) { nodes.each_cons(2).map { |from, to| [from, [to]] }.to_h }
      let(:base) { nodes.map { |node| [node, 0] }.to_h }

      it "propagates the last node's bitmap through a long chain" do
        base[nodes.last] = 1

        expect(described_class.new(nodes, relation, base).compute).to eq(nodes.map { |node| [node, 1] }.to_h)
      end

      it "merges all bitmaps in a long cycle" do
        relation[nodes.last] = [nodes.first]
        base[nodes.first] = 1
        base[nodes.last] = 2

        expect(described_class.new(nodes, relation, base).compute).to eq(nodes.map { |node| [node, 3] }.to_h)
      end
    end
  end
end
