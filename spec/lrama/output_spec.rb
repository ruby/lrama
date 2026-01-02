# frozen_string_literal: true

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

        expect(o).not_to match(/\[@oline@\]/)
        expect(o).not_to match(/\[@ofile@\]/)
        expect(h).not_to match(/\[@oline@\]/)
        expect(h).not_to match(/\[@ofile@\]/)
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

        expect(o).not_to match(/\[@oline@\]/)
        expect(o).not_to match(/\[@ofile@\]/)
      end
    end
  end

  describe "PSLR methods" do
    let(:token_pattern) do
      id = Lrama::Lexer::Token::Ident.new(s_value: "ID")
      regex = Lrama::Lexer::Token::Regex.new(s_value: "/[a-z]+/")
      Lrama::Grammar::TokenPattern.new(
        id: id,
        pattern: regex,
        lineno: 1,
        definition_order: 0
      )
    end

    let(:scanner_fsa) { Lrama::ScannerFSA.new([token_pattern]) }

    let(:mock_states) do
      instance_double(
        Lrama::States,
        scanner_fsa: scanner_fsa,
        scanner_accepts_table: nil,
        length_precedences: nil,
        token_patterns: [token_pattern],
        states: []
      )
    end

    let(:mock_context) do
      instance_double(Lrama::Context, states: mock_states)
    end

    let(:mock_grammar) do
      instance_double(
        Lrama::Grammar,
        eof_symbol: nil,
        error_symbol: nil,
        undef_symbol: nil,
        accept_symbol: nil,
        locations: false,
        parse_param: nil,
        lex_param: nil
      )
    end

    let(:pslr_output) do
      out = StringIO.new
      Lrama::Output.new(
        out: out,
        output_file_path: "test.c",
        template_name: "bison/yacc.c",
        grammar_file_path: "test.y",
        context: mock_context,
        grammar: mock_grammar
      )
    end

    describe "#pslr_enabled?" do
      it "returns true when scanner FSA is built with states" do
        expect(pslr_output.pslr_enabled?).to be true
      end

      it "returns false when scanner FSA is nil" do
        allow(mock_states).to receive(:scanner_fsa).and_return(nil)
        expect(pslr_output.pslr_enabled?).to be false
      end

      it "returns false when scanner FSA has no states" do
        empty_fsa = Lrama::ScannerFSA.new([])
        allow(mock_states).to receive(:scanner_fsa).and_return(empty_fsa)
        expect(pslr_output.pslr_enabled?).to be false
      end
    end

    describe "#scanner_transition_table" do
      it "generates C code for scanner transitions" do
        result = pslr_output.scanner_transition_table
        expect(result).to include("YY_SCANNER_NUM_STATES")
        expect(result).to include("yy_scanner_transition")
      end
    end

    describe "#pseudo_scan_function" do
      it "generates the pseudo_scan C function" do
        result = pslr_output.pseudo_scan_function
        expect(result).to include("yy_pseudo_scan")
        expect(result).to include("parser_state")
        expect(result).to include("match_length")
      end
    end

    describe "#pslr_tables_and_functions" do
      it "generates all PSLR C code" do
        result = pslr_output.pslr_tables_and_functions
        expect(result).to include("PSLR(1) Scanner Tables and Functions")
        expect(result).to include("YY_SCANNER_NUM_STATES")
        expect(result).to include("yy_scanner_transition")
        expect(result).to include("yy_pseudo_scan")
      end
    end

    describe "#state_to_accepting_table" do
      it "generates state to accepting mapping" do
        result = pslr_output.state_to_accepting_table
        expect(result).to include("yy_state_to_accepting")
        expect(result).to include("YY_ACCEPTING_NONE")
      end
    end

    describe "#length_precedences_table_code" do
      let(:mock_length_prec) { Lrama::LengthPrecedences.new(Lrama::Grammar::LexPrec.new) }

      before do
        allow(mock_states).to receive(:length_precedences).and_return(mock_length_prec)
      end

      it "generates length precedences table" do
        result = pslr_output.length_precedences_table_code
        expect(result).to include("length_precedences")
        expect(result).to include("YY_LENGTH_PREC_UNDEFINED")
      end
    end

    describe "#accepting_tokens_table" do
      it "generates accepting tokens information" do
        result = pslr_output.accepting_tokens_table
        expect(result).to include("Accepting state token IDs")
      end
    end
  end

  describe "PSLR integration in render" do
    let(:pslr_grammar_text) do
      <<~GRAMMAR
        %token-pattern RSHIFT />>/ "right shift"
        %token-pattern RANGLE />/ "right angle"
        %lex-prec RANGLE -s RSHIFT
        %%
        program: RSHIFT | RANGLE
      GRAMMAR
    end

    let(:pslr_grammar) do
      grammar = Lrama::Parser.new(pslr_grammar_text, "pslr_test.y").parse
      grammar.prepare
      grammar.validate!
      grammar
    end

    let(:pslr_states) do
      s = Lrama::States.new(pslr_grammar, Lrama::Tracer.new(Lrama::Logger.new))
      s.compute
      s.compute_pslr
      s
    end

    let(:pslr_context) { Lrama::Context.new(pslr_states) }
    let(:pslr_out) { StringIO.new }

    let(:pslr_full_output) do
      Lrama::Output.new(
        out: pslr_out,
        output_file_path: "pslr_test.c",
        template_name: "bison/yacc.c",
        grammar_file_path: "pslr_test.y",
        context: pslr_context,
        grammar: pslr_grammar
      )
    end

    it "includes PSLR tables in rendered output" do
      pslr_full_output.render
      pslr_out.rewind
      rendered = pslr_out.read

      expect(rendered).to include("PSLR(1) Scanner Tables and Functions")
      expect(rendered).to include("YY_SCANNER_NUM_STATES")
      expect(rendered).to include("yy_scanner_transition")
      expect(rendered).to include("yy_pseudo_scan")
    end
  end
end
