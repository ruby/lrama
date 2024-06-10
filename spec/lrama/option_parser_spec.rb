# frozen_string_literal: true

require "open3"

RSpec.describe Lrama::OptionParser do
  describe "invalid argv" do
    context "when grammar file isn't specified" do
      it "returns stderr" do
        result = Open3.popen3("ruby", exe_path("lrama")) do |stdin, stdout, stderr, wait_thr|
          stderr.read
        end
        expect(result).to eq("File should be specified\n")
      end
    end

    context "when STDIN mode, but a grammar file isn't specified" do
      it "returns stderr" do
        result = Open3.popen3("ruby", exe_path("lrama"), "-") do |stdin, stdout, stderr, wait_thr|
          stderr.read
        end
        expect(result).to eq("File name for STDIN should be specified\n")
      end
    end
  end

  describe "version option" do
    it "print Lrama version and exit" do
      result = Open3.popen3("ruby", exe_path("lrama"), "--version") do |stdin, stdout, stderr, wait_thr|
        stdout.read
      end
      expect(result).to eq("lrama #{Lrama::VERSION}\n")
    end
  end

  describe "help option" do
    it "print help and exit" do
      ["--help", "-h"].each do |help|
        result = Open3.popen3("ruby", exe_path("lrama"), help) do |stdin, stdout, stderr, wait_thr|
          stdout.read
        end
        expect(result).to eq(<<~HELP)
          Lrama is LALR (1) parser generator written by Ruby.

          Usage: lrama [options] FILE

          STDIN mode:
          lrama [options] - FILE               read grammar from STDIN

          Tuning the Parser:
              -S, --skeleton=FILE              specify the skeleton to use
              -t                               reserved, do nothing
                  --debug                      display debugging outputs of internal parser

          Output:
              -H, --header=[FILE]              also produce a header file named FILE
              -d                               also produce a header file
              -r, --report=THINGS              also produce details on the automaton
                  --report-file=FILE           also produce details on the automaton output to a file named FILE
              -o, --output=FILE                leave output to FILE
                  --trace=THINGS               also output trace logs at runtime
              -v                               reserved, do nothing

          Error Recovery:
              -e                               enable error recovery

          Other options:
              -V, --version                    output version information and exit
              -h, --help                       display this help and exit

          Valid Reports:
              states itemsets lookaheads solved counterexamples all rules terms verbose

          Valid Traces:
              none locations scan parse automaton bitsets closure grammar rules actions resource sets muscles tools m4-early m4 skeleton time ielr cex all

        HELP
      end
    end
  end

  describe "#validate_report" do
    let(:option_parser) { Lrama::OptionParser.new }

    describe "valid options are passed" do
      it "returns option hash" do
        opts = option_parser.send(:validate_report, ["states", "itemsets"])
        expect(opts).to eq({grammar: true, states: true, itemsets: true})
      end

      describe "all is passed" do
        it "returns option hash all flags enabled" do
          opts = option_parser.send(:validate_report, ["all"])
          expect(opts).to eq({
            grammar: true, states: true, itemsets: true,
            lookaheads: true, solved: true, counterexamples: true,
          })
        end
      end
    end

    describe "invalid options are passed" do
      it "returns option hash" do
        expect { option_parser.send(:validate_report, ["invalid"]) }.to raise_error(/Invalid report option/)
      end
    end
  end

  describe "@grammar_file" do
    context "file is specified" do
      it "@grammar_file is file name" do
        option_parser = Lrama::OptionParser.new
        option_parser.send(:parse, [fixture_path("command/basic.y")])
        options = option_parser.instance_variable_get(:@options)
        expect(options.grammar_file).to match(/command\/basic\.y/)
      end
    end

    context "file name is specified after '-'" do
      it "@grammar_file is file name" do
        option_parser = Lrama::OptionParser.new
        option_parser.send(:parse, ["-", "test.y"])
        options = option_parser.instance_variable_get(:@options)
        expect(options.grammar_file).to eq "test.y"
      end
    end
  end

  describe "@outfile" do
    context "output option is not passed" do
      it "@outfile is default value" do
        option_parser = Lrama::OptionParser.new
        option_parser.send(:parse, ["-", "test.y"])
        options = option_parser.instance_variable_get(:@options)
        expect(options.outfile).to eq "y.tab.c"
      end
    end

    context "output option is passed" do
      it "@outfile is same with passed value" do
        option_parser = Lrama::OptionParser.new
        option_parser.send(:parse, ["-o", "parse.c", "-", "test.y"])
        options = option_parser.instance_variable_get(:@options)
        expect(options.outfile).to eq "parse.c"
      end
    end
  end

  describe "@header_file" do
    context "header file name is not passed" do
      context "outfile option is passed" do
        it "@header_file is set based on outfile" do
          option_parser = Lrama::OptionParser.new
          option_parser.send(:parse, ["-H", "-o", "parse.c", "-", "test.y"])
          options = option_parser.instance_variable_get(:@options)
          expect(options.header_file).to eq "./parse.h"
        end
      end

      context "outfile option is not passed" do
        it "@header_file is set based on outfile default value" do
          option_parser = Lrama::OptionParser.new
          option_parser.send(:parse, ["-H", "-", "test.y"])
          options = option_parser.instance_variable_get(:@options)
          expect(options.header_file).to eq "./y.tab.h"
        end
      end
    end

    context "header file name is passed" do
      it "@header_file is same with passed value" do
        option_parser = Lrama::OptionParser.new
        option_parser.send(:parse, ["-Hparse.h", "-", "test.y"])
        options = option_parser.instance_variable_get(:@options)
        expect(options.header_file).to eq "parse.h"
      end
    end
  end

  describe "@report_file" do
    context "report file name is not passed" do
      it "@report_file is set based on grammar file name" do
        option_parser = Lrama::OptionParser.new
        option_parser.send(:parse, ["--report=all", fixture_path("command/basic.y")])
        options = option_parser.instance_variable_get(:@options)
        expect(options.report_file).to match(/command\/basic\.output/)

        option_parser = Lrama::OptionParser.new
        option_parser.send(:parse, ["--report=all", "-", "test.y"])
        options = option_parser.instance_variable_get(:@options)
        expect(options.report_file).to eq "./test.output"
      end
    end

    context "report file name is passed" do
      it "@report_file is same with passed value" do
        option_parser = Lrama::OptionParser.new
        option_parser.send(:parse, ["--report-file=report.output", fixture_path("command/basic.y")])
        options = option_parser.instance_variable_get(:@options)
        expect(options.report_file).to eq "report.output"

        option_parser = Lrama::OptionParser.new
        option_parser.send(:parse, ["--report-file=report.output", "-", "test.y"])
        options = option_parser.instance_variable_get(:@options)
        expect(options.report_file).to eq "report.output"
      end
    end
  end
end
