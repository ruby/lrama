require "stringio"

RSpec.describe Lrama::Output do
  let(:output) {
    Lrama::Output.new(
      out: out,
      output_file_path: "y.tab.c",
      template_name: "bison/yacc.c",
      grammar_file_path: "parse.tmp.y",
      header_out: header_out,
      header_file_path: "y.tab.h",
      context: context,
      grammar: grammar,      
    )
  }
  let(:out) { StringIO.new }
  let(:header_out) { StringIO.new }
  let(:context) { double("context") }
  let(:grammar) { double("grammar") }

  describe "#parse_param" do
    it "returns declaration of parse param without braces" do
      allow(grammar).to receive(:parse_param).and_return("{struct parser_params *p}")
      expect(output.parse_param).to eq("struct parser_params *p")
    end
  end

  describe "#user_formals" do
    it "returns declaration of parse param without braces with a leading comma" do
      allow(grammar).to receive(:parse_param).and_return("{struct parser_params *p}")
      expect(output.user_formals).to eq(", struct parser_params *p")
    end
  end

  describe "#parse_param_name" do
    it "returns name of parse param" do
      allow(grammar).to receive(:parse_param).and_return("{struct parser_params *p}")
      expect(output.parse_param_name).to eq("p")
    end
  end

  describe "#lex_param_name" do
    it "returns name of lex param" do
      allow(grammar).to receive(:lex_param).and_return("{struct parser_params *p}")
      expect(output.lex_param_name).to eq("p")
    end
  end
end
