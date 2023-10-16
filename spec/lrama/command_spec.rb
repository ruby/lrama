require "tmpdir"

RSpec.describe Lrama::Command do
  describe "#run" do
    let(:outfile) { File.join(Dir.tmpdir, "parse.c") }
    let(:o_option) { ["-o", "#{outfile}"] }

    context "when grammar file is specified" do
      it "ends successfully" do
        command = Lrama::Command.new
        expect(command.run(o_option + [fixture_path("command/basic.y")])).to be_nil
      end
    end

    context "when STDIN mode and a grammar file is specified" do
      it "ends successfully" do
        File.open(fixture_path("command/basic.y")) do |f|
          allow(STDIN).to receive(:read).and_return(f.read)
          command = Lrama::Command.new
          expect(command.run(o_option + ["-", "test.y"])).to be_nil
        end
      end
    end

    context "when `--trace=time` option specified" do
      it "called Report::Duration.enable" do
        allow(Lrama::Report::Duration).to receive(:enable)
        command = Lrama::Command.new
        expect(command.run(o_option + [fixture_path("command/basic.y"), "--trace=time"])).to be_nil
        expect(Lrama::Report::Duration).to have_received(:enable).once
      end
    end

    context "when `--report-file` option specified" do
      it "create report file" do
        allow(File).to receive(:open).and_call_original
        command = Lrama::Command.new
        expect(command.run(o_option + [fixture_path("command/basic.y"), "--report-file=report.output"])).to be_nil
        expect(File).to have_received(:open).with("report.output", "w+").once
        expect(File.exist?("report.output")).to be_truthy
        File.delete("report.output")
      end
    end
  end
end
