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

  describe ".render" do
    it "renders a diagram" do
      expect { Lrama::Diagram.render(out: out, grammar: grammar) }.not_to raise_error
      expect(out.string).to include("<h2>$accept</h2>")
      expect(out.string).to include("<h2>unused</h2>")
      expect(out.string).to include("<svg")
    end
  end

  describe ".require_railroad_diagrams" do
    context "when railroad_diagrams is installed" do
      it "requires railroad_diagrams" do
        expect { Lrama::Diagram.require_railroad_diagrams }.not_to raise_error
      end
    end

    context "when railroad_diagrams is not installed" do
      before do
        allow(Lrama::Diagram).to receive(:require).with("railroad_diagrams").and_raise(LoadError)
      end

      it "warns" do
        expect { Lrama::Diagram.require_railroad_diagrams }.to output(/railroad_diagrams is not installed/).to_stderr
      end
    end
  end

  describe "#render" do
    before do
      Lrama::Diagram.require_railroad_diagrams
    end

    it "renders a diagram" do
      expect { diagram.render }.not_to raise_error
      expect(out.string).to include("<h2>$accept</h2>")
      expect(out.string).to include("<h2>unused</h2>")
      expect(out.string).to include("<svg")
    end
  end

  describe "#default_style" do
    before do
      Lrama::Diagram.require_railroad_diagrams
    end

    it "returns the default style" do
      expect(diagram.default_style).to eq RailroadDiagrams::Style::default_style
    end
  end

  describe "#diagrams" do
    before do
      Lrama::Diagram.require_railroad_diagrams
    end

    it "returns diagrams" do
      expect(diagram.diagrams).to include("<h2>$accept</h2>")
      expect(diagram.diagrams).to include("<h2>unused</h2>")
      expect(diagram.diagrams).to include("<svg")
    end
  end
end
