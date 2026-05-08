# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lrama::Reporter::Text do
  describe "#report" do
    it "formats a diagnostic with location and suggestion" do
      diagnostic = Lrama::Diagnostic.new(
        id: "unused_token",
        severity: :warning,
        message: "Token FOO is declared but never used",
        location: Lrama::Diagnostic::Location.new(filename: "sample.y", line: 10, column: 1),
        suggestion: "Remove the token declaration or use it in a rule."
      )

      expect(described_class.new.report([diagnostic])).to eq(<<~TEXT.chomp)
        sample.y:10:1: warning[unused_token]: Token FOO is declared but never used
          suggestion: Remove the token declaration or use it in a rule.
      TEXT
    end

    it "formats a diagnostic without location" do
      diagnostic = Lrama::Diagnostic.new(
        id: "unused_token",
        severity: :warning,
        message: "Token FOO is declared but never used"
      )

      expect(described_class.new.report([diagnostic])).to eq("warning[unused_token]: Token FOO is declared but never used")
    end

    it "keeps multiple diagnostics in input order" do
      first = Lrama::Diagnostic.new(id: "first", severity: :info, message: "First")
      second = Lrama::Diagnostic.new(id: "second", severity: :error, message: "Second")

      expect(described_class.new.report([first, second])).to eq(<<~TEXT.chomp)
        info[first]: First
        error[second]: Second
      TEXT
    end

    it "does not render an empty suggestion" do
      diagnostic = Lrama::Diagnostic.new(
        id: "unused_token",
        severity: :warning,
        message: "Token FOO is declared but never used",
        suggestion: nil
      )

      expect(described_class.new.report([diagnostic])).to eq("warning[unused_token]: Token FOO is declared but never used")
    end
  end
end
