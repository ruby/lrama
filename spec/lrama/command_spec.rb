RSpec.describe Lrama::Command do
  describe "#run" do
    describe "a grammar file is specified" do
      it "ends successfully" do
        command = Lrama::Command.new
        expect(command.run([fixture_path("command/basic.y")])).to be_nil
      end
    end

    describe "STDIN mode and a grammar file is specified" do
      it "ends successfully" do
        File.open(fixture_path("command/basic.y")) do |f|
          allow(STDIN).to receive(:read).and_return(f)
          command = Lrama::Command.new
          expect(command.run(["-", "test.y"])).to be_nil
        end
      end
    end

    describe "invalid argv" do
      describe "a grammar file isn't specified" do
        it "returns stderr" do
          command = Lrama::Command.new
          message = "File should be specified\n"
          allow(STDERR).to receive(:write).with(message)
          expect{ command.run([]) }.to raise_error(SystemExit) do |e|
            expect(e.message).to eq(message)
          end
        end
      end

      describe "STDIN mode, but a grammar file isn't specified" do
        it "returns stderr" do
          command = Lrama::Command.new
          message = "File name for STDIN should be specified\n"
          allow(STDERR).to receive(:write).with(message)
          expect{ command.run(["-"]) }.to raise_error(SystemExit) do |e|
            expect(e.message).to eq(message)
          end
        end
      end
    end
  end
end
