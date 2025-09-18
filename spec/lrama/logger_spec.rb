# frozen_string_literal: true

RSpec.describe Lrama::Logger do
  describe "#line_break" do
    it "prints a line break" do
      out = StringIO.new
      logger = described_class.new(out)
      logger.line_break
      expect(out.string).to eq("\n")
    end
  end

  describe "#trace" do
    it "prints a trace message" do
      out = StringIO.new
      logger = described_class.new(out)
      logger.trace("This is a trace message.")
      expect(out.string).to eq("This is a trace message.\n")
    end
  end

  describe "#warn" do
    it "prints a warning message" do
      out = StringIO.new
      logger = described_class.new(out)
      logger.warn("This is a warning message.")
      expect(out.string).to eq("warning: This is a warning message.\n")
    end
  end

  describe "#error" do
    it "prints an error message" do
      out = StringIO.new
      logger = described_class.new(out)
      logger.error("This is an error message.")
      expect(out.string).to eq("error: This is an error message.\n")
    end
  end
end
