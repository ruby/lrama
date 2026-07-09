# frozen_string_literal: true

RSpec.describe Lrama::Logger do
  after do
    Lrama::Diagnostics::Color.enabled = false
  end

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
    context "when color is disabled" do
      before { Lrama::Diagnostics::Color.enabled = false }

      it "prints a plain warning message" do
        out = StringIO.new
        logger = described_class.new(out)
        logger.warn("This is a warning message.")
        expect(out.string).to eq("warning: This is a warning message.\n")
      end

      context "with location" do
        it "prints a warning message with source location" do
          out = StringIO.new
          logger = described_class.new(out)
          location = double(
            path: "test.y",
            filename: "test.y",
            first_line: 10,
            first_column: 5,
            last_line: 10,
            last_column: 10
          )
          logger.warn("unused rule", location: location, source_line: "  foo: bar")
          expect(out.string).to include("test.y:10.5-10")
          expect(out.string).to include("warning")
          expect(out.string).to include("unused rule")
          expect(out.string).to include("foo: bar")
        end
      end
    end

    context "when color is enabled" do
      before { Lrama::Diagnostics::Color.enabled = true }

      it "prints a colored warning message" do
        out = StringIO.new
        logger = described_class.new(out)
        logger.warn("This is a warning message.")
        expect(out.string).to include("\e[1m")
        expect(out.string).to include("\e[35m")
        expect(out.string).to include("warning")
        expect(out.string).to include("This is a warning message.")
      end
    end
  end

  describe "#error" do
    context "when color is disabled" do
      before { Lrama::Diagnostics::Color.enabled = false }

      it "prints a plain error message" do
        out = StringIO.new
        logger = described_class.new(out)
        logger.error("This is an error message.")
        expect(out.string).to eq("error: This is an error message.\n")
      end

      context "with location" do
        it "prints an error message with source location" do
          out = StringIO.new
          logger = described_class.new(out)
          location = double(
            path: "test.y",
            filename: "test.y",
            first_line: 5,
            first_column: 1,
            last_line: 5,
            last_column: 8
          )
          logger.error("syntax error", location: location, source_line: "invalid;")
          expect(out.string).to include("test.y:5.1-8")
          expect(out.string).to include("error")
          expect(out.string).to include("syntax error")
          expect(out.string).to include("invalid;")
        end
      end
    end

    context "when color is enabled" do
      before { Lrama::Diagnostics::Color.enabled = true }

      it "prints a colored error message" do
        out = StringIO.new
        logger = described_class.new(out)
        logger.error("This is an error message.")
        expect(out.string).to include("\e[1m")
        expect(out.string).to include("\e[31m")
        expect(out.string).to include("error")
        expect(out.string).to include("This is an error message.")
      end
    end
  end
end
