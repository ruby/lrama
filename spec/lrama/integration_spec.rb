# frozen_string_literal: true

require "open3"
require "tempfile"
require "tmpdir"

RSpec.describe "integration" do
  module IntegrationHelper
    @compiled_parsers = {}

    class << self
      attr_accessor :compiled_parsers
    end

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

      cache_key = "#{parser_name}_#{lrama_command_args.join('_')}"

      unless IntegrationHelper.compiled_parsers[cache_key] && File.exist?(obj_path)
        Lrama::Command.new(%W[-H#{parser_h_path} -o#{parser_c_path}] + lrama_command_args + %W[#{grammar_file_path}]).run
        exec_command("flex --header-file=#{lexer_h_path} -o #{lexer_c_path} #{lexer_file_path}")
        exec_command("#{compiler} -Wall -O0 -g -I#{tmpdir} #{parser_c_path} #{lexer_c_path} -o #{obj_path}")
        IntegrationHelper.compiled_parsers[cache_key] = true
      end

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
      exec_command("#{compiler} -Wall -O0 #{c_path} -o #{obj_path}")
    end
  end

  include IntegrationHelper

  # Clear cache after all tests to save memory
  after(:all) do
    IntegrationHelper.compiled_parsers.clear
  end

  describe "calculator" do
    it "returns 9 for '(1+2)*3'" do
      test_parser("calculator", "( 1 + 2 ) * 3", "=> 9")
    end
  end

  describe "parser without %union (YYSTYPE defaults to int)" do
    it "returns 6 for '1 + 2 + 3'" do
      test_parser("no_union", "1 + 2 + 3", "=> 6\n")
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
end
