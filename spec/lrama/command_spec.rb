require "tmpdir"

RSpec.describe Lrama::Command do
  describe "#run" do
    let(:outfile) { File.join(Dir.tmpdir, "parse.c") }
    let(:o_option) { ["-o", "#{outfile}"] }

    describe "a grammar file is specified" do
      it "ends successfully" do
        command = Lrama::Command.new
        expect(command.run(o_option + [fixture_path("command/basic.y")])).to be_nil
      end
    end

    describe "STDIN mode and a grammar file is specified" do
      it "ends successfully" do
        File.open(fixture_path("command/basic.y")) do |f|
          allow(STDIN).to receive(:read).and_return(f.read)
          command = Lrama::Command.new
          expect(command.run(o_option + ["-", "test.y"])).to be_nil
        end
      end
    end
  end
end
