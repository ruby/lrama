# frozen_string_literal: true

require "tmpdir"

RSpec.describe Lrama::Command do
  describe "#run" do
    let(:outfile) { File.join(Dir.tmpdir, "parse.c") }
    let(:o_option) { ["-o", "#{outfile}"] }

    context "when grammar file is specified" do
      it "ends successfully" do
        command = Lrama::Command.new(o_option + [fixture_path("command/basic.y")])
        expect(command.run).to be_nil
      end
    end

    context "when STDIN mode and a grammar file is specified" do
      it "ends successfully" do
        File.open(fixture_path("command/basic.y")) do |f|
          allow(STDIN).to receive(:read).and_return(f.read)
          command = Lrama::Command.new(o_option + ["-", "test.y"])
          expect(command.run).to be_nil
        end
      end
    end

    context "when `--trace=time` option specified" do
      it "called Trace::Duration.enable" do
        allow(Lrama::Tracer::Duration).to receive(:enable)
        command = Lrama::Command.new(o_option + [fixture_path("command/basic.y"), "--trace=time"])
        expect(command.run).to be_nil
        expect(Lrama::Tracer::Duration).to have_received(:enable).once
      end
    end

    context "when `--trace=rules` option specified" do
      it "print grammar rules" do
        command = Lrama::Command.new(o_option + [fixture_path("command/basic.y"), "--trace=rules"])
        expect { command.run }.to output(<<~OUTPUT).to_stderr_from_any_process
          Grammar rules:
          $accept -> list YYEOF
          list -> ε
          list -> list LF
          list -> list expr LF
          expr -> NUM
          expr -> expr '+' expr
          expr -> expr '-' expr
          expr -> expr '*' expr
          expr -> expr '/' expr
          expr -> '(' expr ')'
        OUTPUT
      end
    end

    context "when `--trace=actions` option specified" do
      it "print grammar rules with actions" do
        command = Lrama::Command.new(o_option + [fixture_path("command/basic.y"), "--trace=actions"])
        expect { command.run }.to output(<<~'OUTPUT').to_stderr_from_any_process
          Grammar rules with actions:
          $accept -> list YYEOF {}
          list -> ε {}
          list -> list LF {}
          list -> list expr LF { printf("=> %d\n", $2); }
          expr -> NUM {}
          expr -> expr '+' expr { $$ = $1 + $3; }
          expr -> expr '-' expr { $$ = $1 - $3; }
          expr -> expr '*' expr { $$ = $1 * $3; }
          expr -> expr '/' expr { $$ = $1 / $3; }
          expr -> '(' expr ')' { $$ = $2; }
        OUTPUT
      end
    end

    context "when `--report-file` option specified" do
      it "create report file" do
        allow(File).to receive(:open).and_call_original
        command = Lrama::Command.new(o_option + [fixture_path("command/basic.y"), "--report-file=report.output"])
        expect(command.run).to be_nil
        expect(File).to have_received(:open).with("report.output", "w+").once
        expect(File).to exist("report.output")
        File.delete("report.output")
      end
    end

    context "when a PSLR grammar needs pure-reduce lookahead to choose tokens" do
      let(:outfile) { File.join(Dir.tmpdir, "pslr-pure-reduce.c") }

      before do
        File.delete(outfile) if File.exist?(outfile)
      end

      after do
        File.delete(outfile) if File.exist?(outfile)
      end

      it "emits parser output successfully" do
        command = Lrama::Command.new(["-o", outfile, fixture_path("command/pslr_pure_reduce.y")])

        expect(command.run).to be_nil
        expect(File).to exist(outfile)
      end
    end

    context "when validation aborts" do
      let(:outfile) { File.join(Dir.tmpdir, "validate-abort.c") }

      before do
        File.delete(outfile) if File.exist?(outfile)
      end

      after do
        File.delete(outfile) if File.exist?(outfile)
      end

      it "fails before writing parser output" do
        allow_any_instance_of(Lrama::States).to receive(:validate!).and_raise(SystemExit)

        command = Lrama::Command.new(["-o", outfile, fixture_path("command/basic.y")])

        expect { command.run }.to raise_error(SystemExit)
        expect(File).not_to exist(outfile)
      end
    end

    context "when a PSLR grammar exceeds the configured state limit" do
      let(:outfile) { File.join(Dir.tmpdir, "pslr-growth-limit.c") }

      before do
        File.delete(outfile) if File.exist?(outfile)
      end

      after do
        File.delete(outfile) if File.exist?(outfile)
      end

      it "fails before writing parser output" do
        command = Lrama::Command.new([
          "-Dpslr.max-states=5",
          "-o", outfile,
          fixture_path("command/pslr_growth_limit.y")
        ])

        expect do
          begin
            command.run
          rescue SystemExit
            nil
          end
        end.to output(/error: PSLR state growth exceeded pslr.max-states=5/).to_stderr_from_any_process

        expect(File).not_to exist(outfile)
      end
    end

    context "when PSLR report output is requested" do
      let(:outfile) { File.join(Dir.tmpdir, "pslr-report.c") }
      let(:report_file) { File.join(Dir.tmpdir, "pslr-report.output") }

      before do
        File.delete(outfile) if File.exist?(outfile)
        File.delete(report_file) if File.exist?(report_file)
      end

      after do
        File.delete(outfile) if File.exist?(outfile)
        File.delete(report_file) if File.exist?(report_file)
      end

      it "writes PSLR metrics into the report file" do
        command = Lrama::Command.new([
          "--report=pslr",
          "--report-file=#{report_file}",
          "-o", outfile,
          fixture_path("command/pslr_growth_limit.y")
        ])

        expect(command.run).to be_nil
        report = File.read(report_file)
        expect(report).to include("PSLR Summary")
        expect(report).to include("Base states:")
        expect(report).to include("Total states:")
      end
    end
  end
end
