# frozen_string_literal: true

RSpec.describe Lrama::Diagram do
  let(:diagram) {
    Lrama::Diagram.new(
      out: out,
      grammar: grammar,
      template_name: "diagram/diagram.html",
    )
  }
  let(:out) { StringIO.new }
  let(:grammar_file_path) { fixture_path("common/basic.y") }
  let(:text) { File.read(grammar_file_path) }
  let(:grammar) do
    grammar = Lrama::Parser.new(text, grammar_file_path).parse
    grammar.prepare
    grammar.validate!
    grammar
  end


  describe "#default_style" do
    it "returns the default style" do
      expect(diagram.default_style).to eq RailroadDiagrams::Style::default_style
    end
  end

  describe "#diagrams" do
    it "returns diagrams" do
      expect(diagram.diagrams).to include("<h2>$accept</h2>")
      expect(diagram.diagrams).to include("<h2>unused</h2>")
      expect(diagram.diagrams).to include("<svg")
    end
  end
end
