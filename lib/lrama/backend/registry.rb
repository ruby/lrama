# frozen_string_literal: true

module Lrama
  module Backend
    @registry = {}

    class << self
      def register(name, klass)
        @registry[name.to_sym] = klass
      end

      def for(name)
        @registry.fetch(name.to_sym) do
          raise "Unknown backend: #{name}. Available: #{available.join(', ')}"
        end
      end

      def available
        @registry.keys
      end
    end
  end
end
