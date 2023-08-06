RSpec.describe Lrama::Command do
  describe "#run" do
    describe "a grammar file is specified " do
      it "ends successfully" do
        command = Lrama::Command.new([fixture_path("command/basic.y")])
        expect(command.run).to be_nil
      end
    end

    describe "STDIN mode and a grammar file is specified" do
      it "ends successfully" do
        File.open(fixture_path("command/basic.y")) do |f|
          allow(STDIN).to receive(:read).and_return(f)
          command = Lrama::Command.new(["-", "test.y"])
          expect(command.run).to be_nil
        end
      end
    end

    describe "invalid argv" do
      describe "a grammar file isn't specified" do
        it "returns stderr" do
          command = Lrama::Command.new([])
          message = "File should be specified\n"
          allow(STDERR).to receive(:write).with(message)
          expect{ command.run }.to raise_error(SystemExit) do |e|
            expect(e.message).to eq(message)
          end
        end
      end

      describe "STDIN mode, but a grammar file isn't specified" do
        it "returns stderr" do
          command = Lrama::Command.new(["-"])
          message = "File name for STDIN should be specified\n"
          allow(STDERR).to receive(:write).with(message)
          expect{ command.run }.to raise_error(SystemExit) do |e|
            expect(e.message).to eq(message)
          end
        end
      end
    end
  end

  describe "#validate_report" do
    let(:command) { Lrama::Command.new([]) }

    describe "valid options are passed" do
      it "returns option hash" do
        opts = command.send(:validate_report, ["states", "itemsets"])
        expect(opts).to eq({grammar: true, states: true, itemsets: true})
      end

      describe "all is passed" do
        it "returns option hash all flags enabled" do
          opts = command.send(:validate_report, ["all"])
          expect(opts).to eq({
            grammar: true, states: true, itemsets: true,
            lookaheads: true, solved: true, counterexamples: true,
          })
        end
      end
    end

    describe "invalid options are passed" do
      it "returns option hash" do
        expect { command.send(:validate_report, ["invalid"]) }.to raise_error(/Invalid report option/)
      end
    end
  end

  describe "@grammar_file" do
    context "file is specified" do
      it "@grammar_file is file name" do
        command = Lrama::Command.new([fixture_path("command/basic.y")])
        command.send(:parse_option)
        expect(command.instance_variable_get(:@grammar_file)).to match(/command\/basic\.y/)
      end
    end

    context "file name is specified after '-'" do
      it "@grammar_file is file name" do
        command = Lrama::Command.new(["-", "test.y"])
        command.send(:parse_option)
        expect(command.instance_variable_get(:@grammar_file)).to eq "test.y"
      end
    end
  end

  describe "@outfile" do
    context "output option is not passed" do
      it "@outfile is default value" do
        command = Lrama::Command.new(["-", "test.y"])
        command.send(:parse_option)
        expect(command.instance_variable_get(:@outfile)).to eq "y.tab.c"
      end
    end

    context "output option is passed" do
      it "@outfile is same with passed value" do
        command = Lrama::Command.new(["-o", "parse.c", "-", "test.y"])
        command.send(:parse_option)
        expect(command.instance_variable_get(:@outfile)).to eq "parse.c"
      end
    end
  end

  describe "@header_file" do
    context "header file name is not passed" do
      context "outfile option is passed" do
        it "@header_file is set based on outfile" do
          command = Lrama::Command.new(["-h", "-o", "parse.c", "-", "test.y"])
          command.send(:parse_option)
          expect(command.instance_variable_get(:@header_file)).to eq "./parse.h"
        end
      end

      context "outfile option is not passed" do
        it "@header_file is set based on outfile default value" do
          command = Lrama::Command.new(["-h", "-", "test.y"])
          command.send(:parse_option)
          expect(command.instance_variable_get(:@header_file)).to eq "./y.tab.h"
        end
      end
    end

    context "header file name is passed" do
      it "@header_file is same with passed value" do
        command = Lrama::Command.new(["-hparse.h", "-", "test.y"])
        command.send(:parse_option)
        expect(command.instance_variable_get(:@header_file)).to eq "parse.h"
      end
    end
  end

  describe "@report_file" do
    context "report file name is not passed" do
      it "@report_file is set based on grammar file name" do
        command = Lrama::Command.new(["--report=all", fixture_path("command/basic.y")])
        command.send(:parse_option)
        expect(command.instance_variable_get(:@report_file)).to match(/command\/basic\.output/)

        command = Lrama::Command.new(["--report=all", "-", "test.y"])
        command.send(:parse_option)
        expect(command.instance_variable_get(:@report_file)).to eq "./test.output"
      end
    end

    context "report file name is passed" do
      it "@report_file is same with passed value" do
        command = Lrama::Command.new(["--report-file=report.output", fixture_path("command/basic.y")])
        command.send(:parse_option)
        expect(command.instance_variable_get(:@report_file)).to eq "report.output"

        command = Lrama::Command.new(["--report-file=report.output", "-", "test.y"])
        command.send(:parse_option)
        expect(command.instance_variable_get(:@report_file)).to eq "report.output"
      end
    end
  end
end
