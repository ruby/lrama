require "open3"
require "tempfile"
require "tmpdir"

RSpec.describe "integration" do
  module IntegrationHelper
    def exec_command(command)
      `#{command}`
      raise "#{command} failed." unless $?.success?
    end

    def test_parser(parser_name, input, expected, lrama_command_args: [], debug: false)
      tmpdir = Dir.tmpdir
      grammar_file_path = fixture_path("integration/#{parser_name}.y")
      lexer_file_path = fixture_path("integration/#{parser_name}.l")
      parser_c_path = tmpdir + "/#{parser_name}.c"
      parser_h_path = tmpdir + "/#{parser_name}.h"
      lexer_c_path = tmpdir + "/#{parser_name}-lexer.c"
      lexer_h_path = tmpdir + "/#{parser_name}-lexer.h"
      obj_path = tmpdir + "/#{parser_name}"

      command = [obj_path, input]
      if ENV['ENABEL_VALGRIND']
        command = ["valgrind", "--leak-check=full", "--show-leak-kinds=all", "--leak-resolution=high"] + command
        debug = true
      end

      Lrama::Command.new.run(%W[-H#{parser_h_path} -o#{parser_c_path}] + lrama_command_args + %W[#{grammar_file_path}])
      exec_command("flex --header-file=#{lexer_h_path} -o #{lexer_c_path} #{lexer_file_path}")
      exec_command("gcc -Wall -ggdb3 -I#{tmpdir} #{parser_c_path} #{lexer_c_path} -o #{obj_path}")

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
      expect(status.success?).to be(true), status.to_s
      expect(out).to eq(expected)
    end

    def generate_object(grammar_file_path, c_path, obj_path, command_args: [])
      Lrama::Command.new.run(%W[-d -o #{c_path}] + command_args + %W[#{grammar_file_path}])
      exec_command("gcc -Wall #{c_path} -o #{obj_path}")
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

  describe "parameterizing rules" do
    it "returns " do
      expected = <<~STR
        odd: 1
        even: 2
        odd: 3
        even: 4
      STR
      test_parser("parameterizing_rules", "1 \n 2; 3 4", expected)
    end
  end

  describe "user defined parameterizing rules" do
    it "prints messages corresponding to rules" do
      expected = <<~STR
        (2, 3)
        pair even odd: 2
        (1, 0)
        pair odd even: 1
      STR
      test_parser("user_defined_parameterizing_rules", "2 3 ; 1 0", expected)
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

  describe "__LINE__ of each place" do
    it "prints line number of each place" do
      expected = <<~STR
        line_pre_program: 31
        line_1: 15
        line_2: 55
        line_post_program: 37
      STR

      test_parser("line_number", "1 + 2", expected)
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
    let(:c_path)   { Dir.tmpdir + "/test.c" }
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
