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

    it "warns about redeclared aliases without -W and still generates a parser" do
      y = "%token PLUS \"+\"\n%token PLUS \"plus\"\n%%\nstart: PLUS \"+\" \"plus\";\n"
      allow(STDIN).to receive(:read).and_return(y)
      command = Lrama::Command.new(o_option + ["-", "redeclared_token.y"])

      expect { command.run }.to output(/symbol PLUS given more than one literal string/).to_stderr_from_any_process
      expect(File.read(outfile)).to include("PLUS =")
      expect(File.read(outfile)).not_to include('"plus" =')
    end

    context "when `--diagram` is specified" do
      it "generates links and reverse references without text diagrams" do
        diagram_file = File.join(Dir.tmpdir, "diagram.html")
        command = Lrama::Command.new(o_option + ["--diagram=#{diagram_file}", fixture_path("command/basic.y")])
        command.run

        html = File.read(diagram_file)
        expect(html).to include('<section id="rule-expr">')
        expect(html).to include('href="#rule-expr"')
        expect(html).to include("Referenced by:")
        expect(html).not_to include("<details", "<pre", "Text diagram")
        expect(html).not_to include("<script")
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

    it "generates an IELR parser with the expected conflict count after cyclic annotation propagation" do
      Dir.mktmpdir do |dir|
        outfile = File.join(dir, "parse.c")
        command = Lrama::Command.new(["-o", outfile, fixture_path("ielr/annotation_cycle.y")])

        expect { command.run }.not_to raise_error
        expect(File).to exist(outfile)
      end
    end

    it "generates a conflict-free IELR parser after merging lookaheads" do
      Dir.mktmpdir do |dir|
        outfile = File.join(dir, "parse.c")
        command = Lrama::Command.new(["-o", outfile, fixture_path("ielr/merged_lookaheads.y")])

        expect { command.run }.not_to raise_error
        expect(File).to exist(outfile)
      end
    end

    [:lalr, :ielr].each do |lr_type|
      it "honors %expect 0 after resolving a previously recorded #{lr_type} shift conflict" do
        Dir.mktmpdir do |dir|
          outfile = File.join(dir, "parse.c")
          command = Lrama::Command.new(["-o", outfile, "-Dlr.type=#{lr_type}",
                                        fixture_path("ielr/resolved_shift_conflicts.y")])

          expect { command.run }.not_to raise_error
          expect(File).to exist(outfile)
        end
      end

      it "honors %expect 0 after discarding #{lr_type} reduction lookaheads" do
        Dir.mktmpdir do |dir|
          outfile = File.join(dir, "parse.c")
          command = Lrama::Command.new(["-o", outfile, "-Dlr.type=#{lr_type}",
                                        fixture_path("ielr/selected_reduction_lookaheads.y")])

          expect { command.run }.not_to raise_error
          expect(File).to exist(outfile)
        end
      end
    end

    it "generates a parser and all reports for duplicate rules on the same line" do
      Dir.mktmpdir do |dir|
        outfile = File.join(dir, "parse.c")
        report = File.join(dir, "parse.output")
        command = Lrama::Command.new(["-o", outfile, "--report=all", "--report-file=#{report}",
                                      fixture_path("ielr/duplicate_rules.y")])

        expect { command.run }.not_to raise_error
        expect(File).to exist(outfile)
        expect(File.read(report)).to include("First Reduce derivation", "Second Reduce derivation")
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

    context "when validation fails with requested reports" do
      let(:outfile) { File.join(Dir.tmpdir, "invalid-parser.c") }
      let(:report_file) { File.join(Dir.tmpdir, "invalid-parser.output") }

      before do
        allow(STDIN).to receive(:read).and_return(source)
      end

      after do
        File.delete(outfile) if File.exist?(outfile)
        File.delete(report_file) if File.exist?(report_file)
      end

      shared_examples "a diagnostic report without parser output" do
        it "writes the requested report before aborting" do
          command = Lrama::Command.new([
            "--report=pslr,states",
            "--report-file=#{report_file}",
            "-o", outfile,
            "-", "invalid.y"
          ])

          expect do
            expect { command.run }.to raise_error(SystemExit)
          end.to output(error_message).to_stderr_from_any_process

          expect(File).to exist(report_file)
          expect(File.read(report_file)).to include(report_message, "State 0")
          expect(File).not_to exist(outfile)
        end
      end

      context "with an unresolved PSLR scanner conflict" do
        let(:source) do
          <<~GRAMMAR
            %define lr.type pslr
            %token-pattern A /a/
            %token-pattern B /a/
            %%
            start: A | B;
          GRAMMAR
        end
        let(:error_message) { /unresolved PSLR scanner conflict/ }
        let(:report_message) { "PSLR Unresolved Scanner Conflicts" }

        include_examples "a diagnostic report without parser output"
      end

      context "with a LALR %expect mismatch" do
        let(:source) do
          <<~GRAMMAR
            %expect 0
            %%
            start: 'a' | start start;
          GRAMMAR
        end
        let(:error_message) { /shift\/reduce conflicts: 1 found, 0 expected/ }
        let(:report_message) { "conflicts: 1 shift/reduce" }

        include_examples "a diagnostic report without parser output"
      end
    end

    it "preserves parser and report files when a split would exceed the state limit" do
      Dir.mktmpdir do |dir|
        outfile = File.join(dir, "parse.c")
        report = File.join(dir, "parse.output")
        File.write(outfile, "previous parser")
        File.write(report, "previous report")
        command = Lrama::Command.new(["-Dpslr.max-states=15", "--report=pslr", "--report-file=#{report}",
                                      "-o", outfile, fixture_path("command/pslr_growth_limit.y")])

        expect do
          expect { command.run }.to raise_error(SystemExit) { |error| expect(error).not_to be_success }
        end.to output(/error: PSLR state growth exceeded pslr.max-states=15/).to_stderr_from_any_process
        expect(File.read(outfile)).to eq("previous parser")
        expect(File.read(report)).to eq("previous report")
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
