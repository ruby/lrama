# frozen_string_literal: true

RSpec.describe Lrama::Backend::C do
  let(:backend) { described_class.new(context: context, grammar: grammar, options: nil) }
  let(:text) { File.read(grammar_file_path) }
  let(:grammar) do
    grammar = Lrama::Parser.new(text, grammar_file_path).parse
    grammar.prepare
    grammar.validate!
    grammar
  end
  let(:states) { s = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new)); s.compute; s }
  let(:context) { Lrama::Context.new(states) }
  let(:grammar_file_path) { fixture_path("common/basic.y") }

  describe ".available" do
    it "registers c backend" do
      expect(Lrama::Backend.available).to include(:c)
      expect(Lrama::Backend.for("c")).to eq(described_class)
    end
  end

  describe "#format_int_array" do
    it "keeps the C table formatting" do
      expect(backend.format_int_array([1, 2, 3])).to eq("       1,     2,     3")
    end
  end

  describe "#int_type_for" do
    it "returns the smallest C integer type used by the skeleton" do
      expect(backend.int_type_for([-1, 127])).to eq("yytype_int8")
      expect(backend.int_type_for([0, 255])).to eq("yytype_uint8")
      expect(backend.int_type_for([-128, 32_767])).to eq("yytype_int16")
      expect(backend.int_type_for([0, 65_535])).to eq("yytype_uint16")
      expect(backend.int_type_for([-32_768, 65_536])).to eq("int")
    end
  end
end
