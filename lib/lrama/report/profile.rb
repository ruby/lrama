# frozen_string_literal: true

module Lrama
  class Report
    module Profile
      # See "Profiling Lrama" in README.md for how to use.
      def self.report_profile(enabled)
        if enabled && require_stackprof
          StackProf.run(mode: :cpu, raw: true, out: 'tmp/stackprof-cpu-myapp.dump') do
            yield
          end
        else
          yield
        end
      end

      def self.require_stackprof
        require "stackprof"
        true
      rescue LoadError
        warn "stackprof is not installed. Please run `bundle install`."
        false
      end
    end
  end
end
