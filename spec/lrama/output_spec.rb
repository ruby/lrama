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
    it "returns declaration of parse param without braces/blanks" do
      allow(grammar).to receive(:parse_param).and_return("{struct parser_params *p}")
      expect(output.parse_param).to eq("struct parser_params *p")

      allow(grammar).to receive(:parse_param).and_return("{ struct parser_params *p  }")
      expect(output.parse_param).to eq("struct parser_params *p")

      allow(grammar).to receive(:parse_param).and_return("{int i}")
      expect(output.parse_param).to eq("int i")

      allow(grammar).to receive(:parse_param).and_return("{ int i  }")
      expect(output.parse_param).to eq("int i")

      allow(grammar).to receive(:parse_param).and_return("{int parse_param}")
      expect(output.parse_param).to eq("int parse_param")

      allow(grammar).to receive(:parse_param).and_return("{ int parse_param  }")
      expect(output.parse_param).to eq("int parse_param")
    end
  end

  describe "#user_formals" do
    context "when parse_param exists" do
      it "returns declaration of parse param without braces/blanks with a leading comma" do
        allow(grammar).to receive(:parse_param).and_return("{struct parser_params *p}")
        expect(output.user_formals).to eq(", struct parser_params *p")

        allow(grammar).to receive(:parse_param).and_return("{ struct parser_params *p  }")
        expect(output.user_formals).to eq(", struct parser_params *p")

        allow(grammar).to receive(:parse_param).and_return("{int i}")
        expect(output.user_formals).to eq(", int i")

        allow(grammar).to receive(:parse_param).and_return("{ int i  }")
        expect(output.user_formals).to eq(", int i")

        allow(grammar).to receive(:parse_param).and_return("{int parse_param}")
        expect(output.user_formals).to eq(", int parse_param")

        allow(grammar).to receive(:parse_param).and_return("{ int parse_param  }")
        expect(output.user_formals).to eq(", int parse_param")
      end
    end

    context "when parse_param does not exist" do
      it "returns blank" do
        allow(grammar).to receive(:parse_param).and_return(nil)
        expect(output.user_formals).to eq("")
      end
    end
  end

  describe "#user_args" do
    context "when parse_param exists" do
      it "returns name of parse param without braces/blanks with a leading comma" do
        allow(grammar).to receive(:parse_param).and_return("{struct parser_params *p}")
        expect(output.user_args).to eq(", p")

        allow(grammar).to receive(:parse_param).and_return("{ struct parser_params *p  }")
        expect(output.user_args).to eq(", p")

        allow(grammar).to receive(:parse_param).and_return("{int i}")
        expect(output.user_args).to eq(", i")

        allow(grammar).to receive(:parse_param).and_return("{ int i  }")
        expect(output.user_args).to eq(", i")

        allow(grammar).to receive(:parse_param).and_return("{int parse_param}")
        expect(output.user_args).to eq(", parse_param")

        allow(grammar).to receive(:parse_param).and_return("{ int parse_param  }")
        expect(output.user_args).to eq(", parse_param")
      end
    end

    context "when parse_param does not exist" do
      it "returns blank" do
        allow(grammar).to receive(:parse_param).and_return(nil)
        expect(output.user_args).to eq("")
      end
    end
  end

  describe "#parse_param_name" do
    it "returns name of parse param" do
      allow(grammar).to receive(:parse_param).and_return("{struct parser_params *p}")
      expect(output.parse_param_name).to eq("p")

      allow(grammar).to receive(:parse_param).and_return("{ struct parser_params *p  }")
      expect(output.parse_param_name).to eq("p")

      allow(grammar).to receive(:parse_param).and_return("{int i}")
      expect(output.parse_param_name).to eq("i")

      allow(grammar).to receive(:parse_param).and_return("{ int i  }")
      expect(output.parse_param_name).to eq("i")

      allow(grammar).to receive(:parse_param).and_return("{int parse_param}")
      expect(output.parse_param_name).to eq("parse_param")

      allow(grammar).to receive(:parse_param).and_return("{ int parse_param  }")
      expect(output.parse_param_name).to eq("parse_param")
    end
  end

  describe "#lex_param_name" do
    it "returns name of lex param" do
      allow(grammar).to receive(:lex_param).and_return("{struct parser_params *p}")
      expect(output.lex_param_name).to eq("p")

      allow(grammar).to receive(:lex_param).and_return("{ struct parser_params *p  }")
      expect(output.lex_param_name).to eq("p")

      allow(grammar).to receive(:lex_param).and_return("{int i}")
      expect(output.lex_param_name).to eq("i")

      allow(grammar).to receive(:lex_param).and_return("{ int i  }")
      expect(output.lex_param_name).to eq("i")

      allow(grammar).to receive(:lex_param).and_return("{int lex_param}")
      expect(output.lex_param_name).to eq("lex_param")

      allow(grammar).to receive(:lex_param).and_return("{ int lex_param  }")
      expect(output.lex_param_name).to eq("lex_param")
    end
  end
end
