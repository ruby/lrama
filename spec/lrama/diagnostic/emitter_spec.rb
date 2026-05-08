# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lrama::Diagnostic::Emitter do
  describe "#warn" do
    it "stores the diagnostic and forwards a compatible warning message" do
      logger = Lrama::Logger.new
      allow(logger).to receive(:warn)
      diagnostic = Lrama::Diagnostic.new(
        id: "unused_token",
        severity: :warning,
        message: "Token FOO is declared but never used"
      )

      emitter = described_class.new(logger)
      emitter.warn(diagnostic)

      expect(emitter.diagnostics).to eq([diagnostic])
      expect(logger).to have_received(:warn).with("Token FOO is declared but never used")
    end

    it "can forward a legacy message while keeping the diagnostic message clean" do
      logger = Lrama::Logger.new
      allow(logger).to receive(:warn)
      diagnostic = Lrama::Diagnostic.new(
        id: "implicit_empty_rule",
        severity: :warning,
        message: "empty rule without %empty"
      )

      emitter = described_class.new(logger)
      emitter.warn(diagnostic, message: "warning: empty rule without %empty")

      expect(emitter.diagnostics).to eq([diagnostic])
      expect(logger).to have_received(:warn).with("warning: empty rule without %empty")
    end
  end

  describe "#error" do
    it "stores the diagnostic and forwards an error message" do
      logger = Lrama::Logger.new
      allow(logger).to receive(:error)
      diagnostic = Lrama::Diagnostic.new(
        id: "conflict.reduce_reduce",
        severity: :error,
        message: "reduce/reduce conflicts: 1 found, 0 expected"
      )

      emitter = described_class.new(logger)
      emitter.error(diagnostic)

      expect(emitter.diagnostics).to eq([diagnostic])
      expect(logger).to have_received(:error).with("reduce/reduce conflicts: 1 found, 0 expected")
    end
  end
end
