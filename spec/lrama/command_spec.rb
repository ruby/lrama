RSpec.describe Lrama::Command do
  describe "#validate_report" do
    let(:command) { Lrama::Command.new }

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
