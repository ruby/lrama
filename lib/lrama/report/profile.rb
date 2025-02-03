# frozen_string_literal: true

module Lrama
  class Report
    module Profile
      # See "Profiling Lrama" in README.md for how to use.
      def self.report_profile
        require_stackprof

        StackProf.run(mode: :cpu, raw: true, out: 'tmp/stackprof-cpu-myapp.dump') do
          yield
        end
      end

      def self.require_stackprof
        require "stackprof"
      rescue LoadError
        warn "stackprof is not installed. Please run `bundle install`."
      end
    end
  end
end
