# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Report
    module Profile
      module CallStack
        # See "Call-stack Profiling Lrama" in README.md for how to use.
        #
        # @rbs enabled: bool
        # @rbs &: -> void
        # @rbs return: StackProf::result | void
        def self.report_profile(enabled)
          if enabled && require_stackprof
            StackProf.run(mode: :cpu, raw: true, out: 'tmp/stackprof-cpu-myapp.dump') do
              yield
            end
          else
            yield
          end
        end

        # @rbs return: bool
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
end
