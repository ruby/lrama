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

    context "when conflicts do not match %expect" do
      it "does not create the parser output" do
        grammar = <<~Y
          %expect 0
          %token NUM
          %%
          expr: NUM | expr '+' expr;
        Y

        Dir.mktmpdir do |dir|
          outfile = File.join(dir, "parse.c")
          allow(STDIN).to receive(:read).and_return(grammar)
          command = Lrama::Command.new(["-o", outfile, "-", "conflict.y"])
          errors = StringIO.new
          command.instance_variable_set(:@logger, Lrama::Logger.new(errors))

          expect { command.run }.to raise_error(SystemExit)
          expect(errors.string).to eq("error: shift/reduce conflicts: 1 found, 0 expected\n")
          expect(File).not_to exist(outfile)
        end
      end
    end

    context "when rendering fails" do
      it "preserves the existing parser output" do
        Dir.mktmpdir do |dir|
          outfile = File.join(dir, "parse.c")
          File.write(outfile, "existing output")
          command = Lrama::Command.new(["-o", outfile, fixture_path("command/basic.y")])
          allow(Lrama::Output).to receive(:new) do |out:, **|
            output = instance_double(Lrama::Output)
            allow(output).to receive(:render) do
              out << "partial output"
              raise "render failed"
            end
            output
          end

          expect { command.run }.to raise_error("render failed")
          expect(File.read(outfile)).to eq("existing output")
        end
      end
    end
  end
end
