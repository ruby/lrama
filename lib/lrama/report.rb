module Lrama
  class Report
    module Profile
      def self.report_profile
        require "stackprof"

        StackProf.run(mode: :cpu, raw: true, out: 'tmp/stackprof-cpu-myapp.dump') do
          yield
        end
      end
    end

    module Duration
      def self.enable
        @_report_duration_enabled = true
      end

      def self.enabled?
        !!@_report_duration_enabled
      end

      def report_duration(method_name)
        time1 = Time.now.to_f
        result = yield
        time2 = Time.now.to_f

        if Duration.enabled?
          puts sprintf("%s %10.5f s", method_name, time2 - time1)
        end

        return result
      end
    end
  end
end
