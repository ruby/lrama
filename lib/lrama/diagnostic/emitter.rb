# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Diagnostic
    class Emitter
      attr_reader :diagnostics #: Array[Lrama::Diagnostic]

      # @rbs (Lrama::Logger logger) -> void
      def initialize(logger)
        @logger = logger
        @diagnostics = [] #: Array[Lrama::Diagnostic]
      end

      # @rbs (Lrama::Diagnostic diagnostic, ?message: String) -> void
      def warn(diagnostic, message: diagnostic.message)
        record(diagnostic)
        @logger.warn(message)
      end

      # @rbs (Lrama::Diagnostic diagnostic, ?message: String) -> void
      def error(diagnostic, message: diagnostic.message)
        record(diagnostic)
        @logger.error(message)
      end

      private

      # @rbs (Lrama::Diagnostic diagnostic) -> void
      def record(diagnostic)
        @diagnostics << diagnostic
      end
    end
  end
end
