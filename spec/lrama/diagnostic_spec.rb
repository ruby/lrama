# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lrama::Diagnostic do
  describe "#initialize" do
    it "keeps diagnostic attributes" do
      location = described_class::Location.new(filename: "sample.y", line: 10, column: 1)
      diagnostic = described_class.new(
        id: "unused_token",
        severity: :warning,
        message: "Token FOO is declared but never used",
        location: location,
        details: { "token" => "FOO" },
        suggestion: "Remove the token declaration or use it in a rule."
      )

      expect(diagnostic.id).to eq("unused_token")
      expect(diagnostic.severity).to eq(:warning)
      expect(diagnostic.message).to eq("Token FOO is declared but never used")
      expect(diagnostic.location).to eq(location)
      expect(diagnostic.details).to eq({ "token" => "FOO" })
      expect(diagnostic.suggestion).to eq("Remove the token declaration or use it in a rule.")
    end

    it "normalizes string severity to symbol" do
      diagnostic = described_class.new(
        id: "unused_token",
        severity: "warning",
        message: "Token FOO is declared but never used"
      )

      expect(diagnostic.severity).to eq(:warning)
    end

    it "uses empty details when details are nil" do
      diagnostic = described_class.new(
        id: "unused_token",
        severity: :warning,
        message: "Token FOO is declared but never used",
        details: nil
      )

      expect(diagnostic.details).to eq({})
    end
  end

  describe "#to_h" do
    it "returns keys in reporter order" do
      diagnostic = described_class.new(
        id: "unused_token",
        severity: :warning,
        message: "Token FOO is declared but never used"
      )

      expect(diagnostic.to_h.keys).to eq(["id", "severity", "message", "location", "suggestion", "details"])
    end
  end

  describe Lrama::Diagnostic::Location do
    it "keeps location attributes" do
      location = described_class.new(filename: "sample.y", line: 10, column: 1, end_line: 10, end_column: 4)

      expect(location.filename).to eq("sample.y")
      expect(location.line).to eq(10)
      expect(location.column).to eq(1)
      expect(location.end_line).to eq(10)
      expect(location.end_column).to eq(4)
    end

    it "allows unknown line and column" do
      location = described_class.new(filename: "sample.y")

      expect(location.line).to be_nil
      expect(location.column).to be_nil
      expect(location.to_h).to eq(
        "filename" => "sample.y",
        "line" => nil,
        "column" => nil,
        "end_line" => nil,
        "end_column" => nil
      )
    end
  end
end
