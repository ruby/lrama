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
          expect{ command.run }.to raise_error(SystemExit) do |e|
            expect(e.message).to eq("File should be specified\n")
          end
        end
      end

      describe "STDIN mode, but a grammar file isn't specified" do
        it "returns stderr" do
          command = Lrama::Command.new(["-"])
          expect{ command.run }.to raise_error(SystemExit) do |e|
            expect(e.message).to eq("File name for STDIN should be specified\n")
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
            lookaheads: true, solved: true,
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
end
