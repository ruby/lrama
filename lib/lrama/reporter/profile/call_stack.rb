# rbs_inline: enabled
# frozen_string_literal: true

require_relative "../../diagnostic"

module Lrama
  class Reporter
    module Profile
      module CallStack
        # See "Call-stack Profiling Lrama" in README.md for how to use.
        #
        # @rbs enabled: bool
        # @rbs &: -> void
        # @rbs return: StackProf::result | void
        def self.report(enabled)
          if enabled && require_stackprof
            ex = nil #: Exception?
            path = 'tmp/stackprof-cpu-myapp.dump'

            StackProf.run(mode: :cpu, raw: true, out: path) do
              yield
            rescue Exception => e
              ex = e
            end

            STDERR.puts("Call-stack Profiling result is generated on #{path}")

            if ex
              raise ex
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
          diagnostic = Lrama::Diagnostic.new(
            id: "dependency.stackprof.missing",
            severity: :warning,
            message: "stackprof is not installed. Please run `bundle install`.",
            details: { "gem" => "stackprof" },
            suggestion: "Run `bundle install`."
          )
          $stderr.puts(diagnostic.message)
          false
        end
      end
    end
  end
end
