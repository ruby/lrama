# frozen_string_literal: true

require "open3"
require "tempfile"
require "tmpdir"

RSpec.describe "integration" do
  module IntegrationHelper
    def exec_command(command)
      `#{command}`
      raise "#{command} failed." unless $?.success?
    end

    def compiler
      ENV['COMPILER'] || "gcc"
    end

    def file_extension
      ['cc', 'gcc', 'clang'].include?(ENV['COMPILER']) ? ".c" : ".cpp"
    end

    def test_parser(parser_name, input, expected, expect_success: true, lrama_command_args: [], debug: false)
      tmpdir = Dir.tmpdir
      grammar_file_path = fixture_path("integration/#{parser_name}.y")
      lexer_file_path = fixture_path("integration/#{parser_name}.l")
      parser_c_path = tmpdir + "/#{parser_name}#{file_extension}"
      parser_h_path = tmpdir + "/#{parser_name}.h"
      lexer_c_path = tmpdir + "/#{parser_name}-lexer#{file_extension}"
      lexer_h_path = tmpdir + "/#{parser_name}-lexer.h"
      obj_path = tmpdir + "/#{parser_name}"

      command = [obj_path, input]
      if ENV['ENABEL_VALGRIND']
        command = ["valgrind", "--leak-check=full", "--show-leak-kinds=all", "--leak-resolution=high"] + command
        debug = true
      end

      Lrama::Command.new(%W[-H#{parser_h_path} -o#{parser_c_path}] + lrama_command_args + %W[#{grammar_file_path}]).run
      exec_command("flex --header-file=#{lexer_h_path} -o #{lexer_c_path} #{lexer_file_path}")
      exec_command("#{compiler} -Wall -ggdb3 -I#{tmpdir} #{parser_c_path} #{lexer_c_path} -o #{obj_path}")

      out = err = status = nil

      Open3.popen3(*command) do |stdin, stdout, stderr, wait_thr|
        out = stdout.read
        err = stderr.read
        status = wait_thr.value
      end

      if debug
        STDERR.puts out
        STDERR.puts err
      end

      expect(status.success?).to be(expect_success), status.to_s
      expect(out).to eq(expected)
    end

    def generate_object(grammar_file_path, c_path, obj_path, command_args: [])
      Lrama::Command.new(%W[-d -o #{c_path}] + command_args + %W[#{grammar_file_path}]).run
      exec_command("#{compiler} -Wall #{c_path} -o #{obj_path}")
    end
  end

  include IntegrationHelper

  describe "calculator" do
    it "returns 9 for '(1+2)*3'" do
      test_parser("calculator", "( 1 + 2 ) * 3", "=> 9")
    end
  end

  it "prologue and epilogue are optional" do
    test_parser("prologue_epilogue_optional", "", "")
  end

  it "contains at reference in action" do
    test_parser("contains_at_reference", "", "")
  end

  describe "YYDEBUG, %lex-param, %parse-param option are enabled" do
    it "returns 9 for '(1+2)*3'" do
      test_parser("params", "(1+2)*3", "=> 9")
    end
  end

  describe "named references" do
    it "returns 3 for '1 2 +" do
      test_parser("named_references", "1 2 +", "expr[ex-left] (1): 1.0-1.1. expr[ex.right] (1): 1.2-1.3. line (1): 1.0-1.5. => 3")
    end
  end

  describe "typed midrule actions" do
    it "returns 4 for '1 2 +" do
      test_parser("typed_midrule_actions", "1 2 +", "=> 4")
    end
  end

  describe "parameterized rules" do
    it "returns " do
      expected = <<~STR
        odd: 1
        even: 2
        odd: 3
        even: 4
      STR
      test_parser("parameterized", "1 \n 2; 3 4", expected)
    end
  end

  describe "user defined parameterized rules" do
    it "prints messages corresponding to rules" do
      expected = <<~STR
        (2, 3)
        (2, 3)
        (-2, -1)
        pair even odd: 5
        (1, 0)
        (1, 0)
        (-2, -1)
        pair odd even: 1
      STR
      test_parser("user_defined_parameterized", "2 3 ; 1 0", expected)
    end
  end

  describe "%printer" do
    it "prints messages" do
      expected = <<~STR.chomp
        val1: 1
        val1: 1
        val1: 1
        expr: 1
        val1: 2
        val1: 2
        val1: 2
        expr: 2
        val1: 3
        val1: 3
        val1: 3
        expr: 3
        expr: 2
        expr: 3
        expr: 6
        expr: 1
        expr: 6
        val2: 7
        val2: 7
        expr: 7
        expr: 7
        => 7
      STR

      test_parser("printers", "1 + 2 * 3", expected)
    end
  end

  describe "%destructor" do
    it "prints messages when symbol is discarded" do
      expected = <<~STR
        destructor for expr: 1
        line for expr: 45
      STR
      test_parser("destructors", "1 +", expected, expect_success: false)

      expected = <<~STR
        destructor for val2: 1
        line for val2: 35
      STR
      test_parser("destructors", "+ 1 -", expected, expect_success: false)

      expected = <<~STR
        => 3
        destructor for val1: 3
        line for val1: 30
      STR
      test_parser("destructors", "1 + 2 3", expected, expect_success: false)

      expected = <<~STR
        destructor for val4: 10
        line for val4: 40
        destructor for expr: 1
        line for expr: 45
      STR
      test_parser("destructors", "1 * ", expected, expect_success: false)
    end
  end

  describe "__LINE__ of each place" do
    it "prints line number of each place" do
      expected = <<~STR
        line_pre_program: 33
        line_1: 15
        line_2: 57
        line_post_program: 39
      STR

      test_parser("line_number", "1 + 2", expected)
    end
  end

  describe "after_shift, before_reduce & after_reduce" do
    it "returns 9 for '(1+2)*3'" do
      expected = <<~STR
        after-shift: 12
        after-shift: 12
        before-reduce: 18, 1
        after-reduce: 24, 1
        after-shift: 12
        after-shift: 12
        before-reduce: 18, 1
        after-reduce: 24, 1
        before-reduce: 18, 3
        + (-3, -2, -1)
        after-reduce: 24, 3
        after-shift: 12
        before-reduce: 18, 3
        (...) (-3, -2, -1)
        after-reduce: 24, 3
        after-shift: 12
        after-shift: 12
        before-reduce: 18, 1
        after-reduce: 24, 1
        before-reduce: 18, 3
        * (-3, -2, -1)
        after-reduce: 24, 3
        before-reduce: 18, 1
        => 9
        after-reduce: 24, 1
        after-shift: 12
      STR

      test_parser("after_shift", "( 1 + 2 ) * 3", expected)

      expected = <<~STR
        after-shift: 12
        before-reduce: 18, 1
        after-reduce: 24, 1
        after-shift: 12
        after-pop-stack: 36, 1
        after-pop-stack: 36, 1
        after-shift-error-token: 30
        before-reduce: 18, 1
        error (-1)
        after-reduce: 24, 1
        after-pop-stack: 36, 1
        after-shift-error-token: 30
        before-reduce: 18, 1
        error (-1)
        after-reduce: 24, 1
        after-pop-stack: 36, 1
        after-shift-error-token: 30
        before-reduce: 18, 1
        error (-1)
        after-reduce: 24, 1
        after-shift: 12
      STR

      test_parser("after_shift", "1 * + 2", expected)
    end
  end

  # TODO: Add test case for "(1+2"
  describe "error_recovery" do
    it "returns 101 for '(1+)'" do
      # (1+) #=> 101
      # '100' is complemented
      test_parser("error_recovery", "(1+)", "=> 101", lrama_command_args: %W[-e])
    end
  end

  describe "sample files" do
    let(:c_path)   { Dir.tmpdir + "/test#{file_extension}" }
    let(:obj_path) { Dir.tmpdir + "/test" }

    describe "calc.y" do
      it "works without errors" do
        expect { generate_object(sample_path("calc.y"), c_path, obj_path) }.not_to raise_error
      end
    end

    describe "parse.y" do
      it "works without errors" do
        expect { generate_object(sample_path("parse.y"), c_path, obj_path) }.not_to raise_error
      end
    end
  end

  describe "PSLR context-dependent lexing" do
    describe "Scanner FSA with overlapping patterns" do
      let(:rangle) do
        id = Lrama::Lexer::Token::Ident.new(s_value: "RANGLE")
        regex = Lrama::Lexer::Token::Regex.new(s_value: "/>/")
        Lrama::Grammar::TokenPattern.new(
          id: id,
          pattern: regex,
          lineno: 1,
          definition_order: 0
        )
      end

      let(:rshift) do
        id = Lrama::Lexer::Token::Ident.new(s_value: "RSHIFT")
        regex = Lrama::Lexer::Token::Regex.new(s_value: "/>>/")
        Lrama::Grammar::TokenPattern.new(
          id: id,
          pattern: regex,
          lineno: 1,
          definition_order: 1
        )
      end

      let(:scanner_fsa) { Lrama::ScannerFSA.new([rangle, rshift]) }

      it "recognizes both RANGLE and RSHIFT as possible matches for '>>'" do
        results = scanner_fsa.scan(">>")

        token_names = results.map { |r| r[:token].name }
        expect(token_names).to include("RANGLE")
        expect(token_names).to include("RSHIFT")
      end

      it "RANGLE matches at position 1, RSHIFT matches at position 2" do
        results = scanner_fsa.scan(">>")

        rangle_match = results.find { |r| r[:token].name == "RANGLE" }
        rshift_match = results.find { |r| r[:token].name == "RSHIFT" }

        expect(rangle_match[:position]).to eq(1)
        expect(rshift_match[:position]).to eq(2)
      end
    end

    describe "Length precedence resolution" do
      let(:lex_prec) { Lrama::Grammar::LexPrec.new }

      before do
        left = Lrama::Lexer::Token::Ident.new(s_value: "RANGLE")
        right = Lrama::Lexer::Token::Ident.new(s_value: "RSHIFT")
        lex_prec.add_rule(
          left_token: left,
          operator: Lrama::Grammar::LexPrec::SHORTER,
          right_token: right,
          lineno: 1
        )
      end

      let(:length_prec) { Lrama::LengthPrecedences.new(lex_prec) }

      it "indicates RANGLE (shorter) should be preferred over RSHIFT (longer)" do
        expect(length_prec.prefer_shorter?("RANGLE", "RSHIFT")).to be true
      end

      it "returns :left precedence for RANGLE vs RSHIFT" do
        expect(length_prec.precedence("RANGLE", "RSHIFT")).to eq(:left)
      end
    end

    describe "Keyword vs identifier precedence" do
      let(:lex_prec) { Lrama::Grammar::LexPrec.new }

      before do
        left = Lrama::Lexer::Token::Ident.new(s_value: "IF")
        right = Lrama::Lexer::Token::Ident.new(s_value: "ID")
        lex_prec.add_rule(
          left_token: left,
          operator: Lrama::Grammar::LexPrec::HIGHER,
          right_token: right,
          lineno: 1
        )
      end

      it "indicates IF has higher priority than ID" do
        expect(lex_prec.higher_priority?("IF", "ID")).to be true
      end

      it "indicates ID does not have higher priority than IF" do
        expect(lex_prec.higher_priority?("ID", "IF")).to be false
      end
    end

    describe "Full PSLR grammar compilation" do
      let(:grammar_text) do
        <<~GRAMMAR
          %token-pattern RSHIFT />>/ "right shift"
          %token-pattern RANGLE />/ "right angle"
          %token-pattern LANGLE /</ "left angle"
          %token-pattern ID /[a-zA-Z_][a-zA-Z0-9_]*/

          %lex-prec RANGLE -s RSHIFT

          %%

          program
            : template_expr
            | shift_expr
            ;

          template_expr
            : ID LANGLE ID RANGLE
            | ID LANGLE ID LANGLE ID RANGLE RANGLE
            ;

          shift_expr
            : ID RSHIFT ID
            ;
        GRAMMAR
      end

      let(:grammar) do
        g = Lrama::Parser.new(grammar_text, "pslr_test.y").parse
        g.prepare
        g.validate!
        g
      end

      let(:states) do
        s = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        s.compute
        s.compute_pslr
        s
      end

      it "builds Scanner FSA from token patterns" do
        expect(states.scanner_fsa).not_to be_nil
        expect(states.scanner_fsa.states).not_to be_empty
      end

      it "builds length precedences from lex-prec rules" do
        expect(states.length_precedences).not_to be_nil
        expect(states.length_precedences.prefer_shorter?("RANGLE", "RSHIFT")).to be true
      end

      it "parses all 4 token patterns" do
        expect(grammar.token_patterns.size).to eq(4)
        names = grammar.token_patterns.map(&:name)
        expect(names).to include("RSHIFT", "RANGLE", "LANGLE", "ID")
      end

      it "Scanner FSA can match overlapping patterns" do
        results = states.scanner_fsa.scan(">>")
        token_names = results.map { |r| r[:token].name }

        expect(token_names).to include("RANGLE")
        expect(token_names).to include("RSHIFT")
      end

      describe "context-dependent token selection" do
        it "scanner_accepts table is built" do
          expect(states.scanner_accepts_table).not_to be_nil
        end

        it "different parser states may accept different tokens for same FSA state" do
          scanner_accepts = states.scanner_accepts_table
          scanner_fsa = states.scanner_fsa

          results = scanner_fsa.scan(">>")
          rshift_result = results.find { |r| r[:token].name == "RSHIFT" }
          rangle_result = results.find { |r| r[:token].name == "RANGLE" }

          expect(rshift_result).not_to be_nil
          expect(rangle_result).not_to be_nil
          expect(scanner_accepts.table).to be_a(Hash)
        end
      end

      describe "generated C code output" do
        let(:out) { StringIO.new }
        let(:context) { Lrama::Context.new(states) }
        let(:output) do
          Lrama::Output.new(
            out: out,
            output_file_path: "pslr_test.c",
            template_name: "bison/yacc.c",
            grammar_file_path: "pslr_test.y",
            context: context,
            grammar: grammar
          )
        end

        before do
          output.render
          out.rewind
        end

        let(:rendered) { out.read }

        it "includes yy_scanner_transition table" do
          expect(rendered).to include("yy_scanner_transition")
          expect(rendered).to include("YY_SCANNER_NUM_STATES")
        end

        it "includes yy_state_to_accepting mapping" do
          expect(rendered).to include("yy_state_to_accepting")
          expect(rendered).to include("YY_ACCEPTING_NONE")
        end

        it "includes yy_length_precedences table" do
          expect(rendered).to include("yy_length_precedences")
          expect(rendered).to include("YY_LENGTH_PREC_LEFT")
        end

        it "includes yy_pseudo_scan function" do
          expect(rendered).to include("yy_pseudo_scan")
          expect(rendered).to include("parser_state")
          expect(rendered).to include("match_length")
        end

        it "pseudo_scan function uses length precedences for token selection" do
          expect(rendered).to include("yy_length_precedences[tbest][t]")
        end
      end
    end
  end
end
