# frozen_string_literal: true

require "json"
require "spec_helper"

RSpec.describe Lrama::Reporter::JSON do
  describe "#report" do
    it "formats diagnostics as parseable JSON with fixed key order" do
      diagnostic = Lrama::Diagnostic.new(
        id: "unused_token",
        severity: :warning,
        message: "Token FOO is declared but never used",
        location: Lrama::Diagnostic::Location.new(filename: "sample.y", line: 10, column: 1),
        details: {},
        suggestion: "Remove the token declaration or use it in a rule."
      )

      json = described_class.new.report([diagnostic])

      expect(JSON.parse(json)).to eq(
        "diagnostics" => [
          {
            "id" => "unused_token",
            "severity" => "warning",
            "message" => "Token FOO is declared but never used",
            "location" => {
              "filename" => "sample.y",
              "line" => 10,
              "column" => 1,
              "end_line" => nil,
              "end_column" => nil
            },
            "suggestion" => "Remove the token declaration or use it in a rule.",
            "details" => {}
          }
        ]
      )
      expect(JSON.parse(json)["diagnostics"].first.keys).to eq(["id", "severity", "message", "location", "suggestion", "details"])
    end

    it "keeps multiple diagnostics in input order" do
      first = Lrama::Diagnostic.new(id: "first", severity: :info, message: "First")
      second = Lrama::Diagnostic.new(id: "second", severity: :error, message: "Second")

      diagnostics = JSON.parse(described_class.new.report([first, second])).fetch("diagnostics")

      expect(diagnostics.map { |diagnostic| diagnostic.fetch("id") }).to eq(["first", "second"])
    end

    it "handles nil suggestion and empty details" do
      diagnostic = Lrama::Diagnostic.new(
        id: "unused_token",
        severity: "warning",
        message: "Token FOO is declared but never used",
        details: nil,
        suggestion: nil
      )

      expect(JSON.parse(described_class.new.report([diagnostic]))).to eq(
        "diagnostics" => [
          {
            "id" => "unused_token",
            "severity" => "warning",
            "message" => "Token FOO is declared but never used",
            "location" => nil,
            "suggestion" => nil,
            "details" => {}
          }
        ]
      )
    end
  end
end
