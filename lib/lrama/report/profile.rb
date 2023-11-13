module Lrama
  class Report
    module Profile
      # 1. Wrap target method with Profile.report_profile like below:
      #
      #   Lrama::Report::Profile.report_profile { method }
      #
      # 2. Run lrama command, for example
      #
      #   $ ./exe/lrama --trace=time sample/parse_for_report_profile.y
      #
      # 3. Generate html file
      #
      #   $ stackprof --d3-flamegraph tmp/stackprof-cpu-myapp.dump > tmp/flamegraph.html
      #
      def self.report_profile
        require "stackprof"

        StackProf.run(mode: :cpu, raw: true, out: 'tmp/stackprof-cpu-myapp.dump') do
          yield
        end
      end
    end
  end
end
