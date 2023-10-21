require "stringio"

RSpec.describe Lrama::Output do
  let(:output) {
    Lrama::Output.new(
      out: out,
      output_file_path: "y.tab.c",
      template_name: "bison/yacc.c",
      grammar_file_path: grammar_file_path,
      header_out: header_out,
      header_file_path: header_file_path,
      context: context,
      grammar: grammar,
    )
  }
  let(:out) { StringIO.new }
  let(:header_out) { StringIO.new }
  let(:warning) { Lrama::Warning.new(StringIO.new) } # suppress warnings
  let(:text) { File.read(grammar_file_path) }
  let(:grammar) { Lrama::Parser.new(text).parse }
  let(:states) { s = Lrama::States.new(grammar, warning); s.compute; s }
  let(:context) { Lrama::Context.new(states) }
  let(:grammar_file_path) { fixture_path("common/basic.y") }
  let(:header_file_path) { "y.tab.h" }

  describe "#parse_param" do
    it "returns declaration of parse param without blanks" do
      allow(grammar).to receive(:parse_param).and_return("struct parser_params *p")
      expect(output.parse_param).to eq("struct parser_params *p")

      allow(grammar).to receive(:parse_param).and_return(" struct parser_params *p  ")
      expect(output.parse_param).to eq("struct parser_params *p")

      allow(grammar).to receive(:parse_param).and_return("int i")
      expect(output.parse_param).to eq("int i")

      allow(grammar).to receive(:parse_param).and_return(" int i  ")
      expect(output.parse_param).to eq("int i")

      allow(grammar).to receive(:parse_param).and_return("int parse_param")
      expect(output.parse_param).to eq("int parse_param")

      allow(grammar).to receive(:parse_param).and_return(" int parse_param  ")
      expect(output.parse_param).to eq("int parse_param")
    end
  end

  describe "#user_formals" do
    context "when parse_param exists" do
      it "returns declaration of parse param without blanks with a leading comma" do
        allow(grammar).to receive(:parse_param).and_return("struct parser_params *p")
        expect(output.user_formals).to eq(", struct parser_params *p")

        allow(grammar).to receive(:parse_param).and_return(" struct parser_params *p  ")
        expect(output.user_formals).to eq(", struct parser_params *p")

        allow(grammar).to receive(:parse_param).and_return("int i")
        expect(output.user_formals).to eq(", int i")

        allow(grammar).to receive(:parse_param).and_return(" int i  ")
        expect(output.user_formals).to eq(", int i")

        allow(grammar).to receive(:parse_param).and_return("int parse_param")
        expect(output.user_formals).to eq(", int parse_param")

        allow(grammar).to receive(:parse_param).and_return(" int parse_param  ")
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
      it "returns name of parse param without blanks with a leading comma" do
        allow(grammar).to receive(:parse_param).and_return("struct parser_params *p")
        expect(output.user_args).to eq(", p")

        allow(grammar).to receive(:parse_param).and_return(" struct parser_params *p  ")
        expect(output.user_args).to eq(", p")

        allow(grammar).to receive(:parse_param).and_return("int i")
        expect(output.user_args).to eq(", i")

        allow(grammar).to receive(:parse_param).and_return(" int i  ")
        expect(output.user_args).to eq(", i")

        allow(grammar).to receive(:parse_param).and_return("int parse_param")
        expect(output.user_args).to eq(", parse_param")

        allow(grammar).to receive(:parse_param).and_return(" int parse_param  ")
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
      allow(grammar).to receive(:parse_param).and_return("struct parser_params *p")
      expect(output.parse_param_name).to eq("p")

      allow(grammar).to receive(:parse_param).and_return(" struct parser_params *p  ")
      expect(output.parse_param_name).to eq("p")

      allow(grammar).to receive(:parse_param).and_return("int i")
      expect(output.parse_param_name).to eq("i")

      allow(grammar).to receive(:parse_param).and_return(" int i  ")
      expect(output.parse_param_name).to eq("i")

      allow(grammar).to receive(:parse_param).and_return("int parse_param")
      expect(output.parse_param_name).to eq("parse_param")

      allow(grammar).to receive(:parse_param).and_return(" int parse_param  ")
      expect(output.parse_param_name).to eq("parse_param")
    end
  end

  describe "#lex_param_name" do
    it "returns name of lex param" do
      allow(grammar).to receive(:lex_param).and_return("struct parser_params *p")
      expect(output.lex_param_name).to eq("p")

      allow(grammar).to receive(:lex_param).and_return(" struct parser_params *p  ")
      expect(output.lex_param_name).to eq("p")

      allow(grammar).to receive(:lex_param).and_return("int i")
      expect(output.lex_param_name).to eq("i")

      allow(grammar).to receive(:lex_param).and_return(" int i  ")
      expect(output.lex_param_name).to eq("i")

      allow(grammar).to receive(:lex_param).and_return("int lex_param")
      expect(output.lex_param_name).to eq("lex_param")

      allow(grammar).to receive(:lex_param).and_return(" int lex_param  ")
      expect(output.lex_param_name).to eq("lex_param")
    end
  end

  describe "#render" do
    context "header_file_path is specified" do
      before do
        output.render
        out.rewind
        header_out.rewind
      end

      it "renders C file and header file" do
        expect(out.size).not_to eq 0
        expect(header_out.size).not_to eq 0
      end

      it "doesn't include [@oline@] and [@ofile@] in files" do
        o = out.read
        h = header_out.read

        expect(o).not_to match /\[@oline@\]/
        expect(o).not_to match /\[@ofile@\]/
        expect(h).not_to match /\[@oline@\]/
        expect(h).not_to match /\[@ofile@\]/
      end
    end

    context "header_file_path is not specified" do
      let(:header_file_path) { nil }

      before do
        output.render
        out.rewind
        header_out.rewind
      end

      it "renders only C file" do
        expect(out.size).not_to eq 0
        expect(header_out.size).to eq 0
      end

      it "doesn't include [@oline@] and [@ofile@] in a file" do
        o = out.read

        expect(o).not_to match /\[@oline@\]/
        expect(o).not_to match /\[@ofile@\]/
      end
    end
  end
end
