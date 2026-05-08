# rbs_inline: enabled
# frozen_string_literal: true

require_relative "diagnostic/location"

module Lrama
  class Diagnostic
    attr_reader :id #: String
    attr_reader :severity #: Symbol
    attr_reader :message #: String
    attr_reader :location #: Location?
    attr_reader :details #: Hash[untyped, untyped]
    attr_reader :suggestion #: String?

    # @rbs (id: String, severity: Symbol | String, message: String, ?location: Location?, ?details: Hash[untyped, untyped]?, ?suggestion: String?) -> void
    def initialize(id:, severity:, message:, location: nil, details: nil, suggestion: nil)
      @id = id
      @severity = severity.to_sym
      @message = message
      @location = location
      empty_details = {} #: Hash[untyped, untyped]
      @details = details || empty_details
      @suggestion = suggestion
    end

    # @rbs () -> Hash[String, untyped]
    def to_h
      {
        "id" => id,
        "severity" => severity.to_s,
        "message" => message,
        "location" => location&.to_h,
        "suggestion" => suggestion,
        "details" => details
      }
    end
  end
end
