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
        emit(:warn, diagnostic, message)
      end

      # @rbs (Lrama::Diagnostic diagnostic, ?message: String) -> void
      def error(diagnostic, message: diagnostic.message)
        emit(:error, diagnostic, message)
      end

      private

      # @rbs (Symbol level, Lrama::Diagnostic diagnostic, String message) -> void
      def emit(level, diagnostic, message)
        @diagnostics << diagnostic
        @logger.public_send(level, message)
      end
    end
  end
end
