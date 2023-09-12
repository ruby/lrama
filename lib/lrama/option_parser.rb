require 'optparse'

module Lrama
  # Handle option parsing for the command line interface.
  class OptionParser
    def initialize
      @options = Options.new
    end

    def parse(argv)
      parse_by_option_parser(argv)

      @options.trace_opts = validate_trace(@options.trace)
      @options.report_opts = validate_report(@options.report)

      @options.grammar_file = argv.shift

      if !@options.grammar_file
        abort "File should be specified\n"
      end

      if @options.grammar_file == '-'
        @options.grammar_file = argv.shift or abort "File name for STDIN should be specified\n"
      else
        @options.y = File.open(@options.grammar_file, 'r')
      end

      if !@options.report.empty? && @options.report_file.nil? && @options.grammar_file
        @options.report_file = File.dirname(@options.grammar_file) + "/" + File.basename(@options.grammar_file, ".*") + ".output"
      end

      if !@options.header_file && @options.header
        case
        when @options.outfile
          @options.header_file = File.dirname(@options.outfile) + "/" + File.basename(@options.outfile, ".*") + ".h"
        when @options.grammar_file
          @options.header_file = File.dirname(@options.grammar_file) + "/" + File.basename(@options.grammar_file, ".*") + ".h"
        end
      end

      @options
    end

    private

    def parse_by_option_parser(argv)
      ::OptionParser.new do |o|

        # opt.on('-h') {|v| p v }
        o.on('-V', '--version') {|v| puts "lrama #{Lrama::VERSION}"; exit 0 }

        # Tuning the Parser
        o.on('-S', '--skeleton=FILE') {|v| @options.skeleton = v }
        o.on('-t') {  } # Do nothing

        # Output Files:
        o.on('-h', '--header=[FILE]') {|v| @options.header = true; @options.header_file = v }
        o.on('-d') { @options.header = true }
        o.on('-r', '--report=THINGS', Array) {|v| @options.report = v }
        o.on('--report-file=FILE')    {|v| @options.report_file = v }
        o.on('-v') {  } # Do nothing
        o.on('-o', '--output=FILE')   {|v| @options.outfile = v }

        # Hidden
        o.on('--trace=THINGS', Array) {|v| @options.trace = v }

        # Error Recovery
        o.on('-e') {|v| @options.error_recovery = true }

        o.parse!(argv)
      end
    end

    def validate_report(report)
      bison_list = %w[states itemsets lookaheads solved counterexamples cex all none]
      others = %w[verbose]
      list = bison_list + others
      not_supported = %w[cex none]
      h = { grammar: true }

      report.each do |r|
        if list.include?(r) && !not_supported.include?(r)
          h[r.to_sym] = true
        else
          raise "Invalid report option \"#{r}\"."
        end
      end

      if h[:all]
        (bison_list - not_supported).each do |r|
          h[r.to_sym] = true
        end

        h.delete(:all)
      end

      return h
    end

    def validate_trace(trace)
      list = %w[
        none locations scan parse automaton bitsets
        closure grammar resource sets muscles tools
        m4-early m4 skeleton time ielr cex all
      ]
      h = {}

      trace.each do |t|
        if list.include?(t)
          h[t.to_sym] = true
        else
          raise "Invalid trace option \"#{t}\"."
        end
      end

      return h
    end
  end
end
