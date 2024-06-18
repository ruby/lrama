# frozen_string_literal: true

require 'optparse'

module Lrama
  # Handle option parsing for the command line interface.
  class OptionParser
    def initialize
      @options = Options.new
      @trace = []
      @report = []
    end

    def parse(argv)
      parse_by_option_parser(argv)

      @options.trace_opts = validate_trace(@trace)
      @options.report_opts = validate_report(@report)
      @options.diagnostic_opts = validate_diagnostic(@diagnostic)
      @options.grammar_file = argv.shift

      if !@options.grammar_file
        abort "File should be specified\n"
      end

      if @options.grammar_file == '-'
        @options.grammar_file = argv.shift or abort "File name for STDIN should be specified\n"
      else
        @options.y = File.open(@options.grammar_file, 'r')
      end

      if !@report.empty? && @options.report_file.nil? && @options.grammar_file
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
        o.banner = <<~BANNER
          Lrama is LALR (1) parser generator written by Ruby.

          Usage: lrama [options] FILE
        BANNER
        o.separator ''
        o.separator 'STDIN mode:'
        o.separator 'lrama [options] - FILE               read grammar from STDIN'
        o.separator ''
        o.separator 'Tuning the Parser:'
        o.on('-S', '--skeleton=FILE', 'specify the skeleton to use') {|v| @options.skeleton = v }
        o.on('-t', 'reserved, do nothing') { }
        o.on('--debug', 'display debugging outputs of internal parser') {|v| @options.debug = true }
        o.separator ''
        o.separator 'Output:'
        o.on('-H', '--header=[FILE]', 'also produce a header file named FILE') {|v| @options.header = true; @options.header_file = v }
        o.on('-d', 'also produce a header file') { @options.header = true }
        o.on('-r', '--report=REPORTS', Array, 'also produce details on the automaton') {|v| @report = v }
        o.on_tail ''
        o.on_tail 'REPORTS is a list of comma-separated words that can include:'
        o.on_tail '    states                           describe the states'
        o.on_tail '    itemsets                         complete the core item sets with their closure'
        o.on_tail '    lookaheads                       explicitly associate lookahead tokens to items'
        o.on_tail '    solved                           describe shift/reduce conflicts solving'
        o.on_tail '    counterexamples, cex             generate conflict counterexamples'
        o.on_tail '    rules                            list unused rules'
        o.on_tail '    terms                            list unused terminals'
        o.on_tail '    verbose                          report detailed internal state and analysis results'
        o.on_tail '    all                              include all the above reports'
        o.on_tail '    none                             disable all reports'
        o.on('--report-file=FILE', 'also produce details on the automaton output to a file named FILE') {|v| @options.report_file = v }
        o.on('-o', '--output=FILE', 'leave output to FILE') {|v| @options.outfile = v }

        o.on('--trace=THINGS', Array, 'also output trace logs at runtime') {|v| @trace = v }
        o.on_tail ''
        o.on_tail 'Valid Traces:'
        o.on_tail "    #{VALID_TRACES.join(' ')}"

        o.on('-v', 'reserved, do nothing') { }
        o.separator ''
        o.separator 'Diagnostics:'
        o.on('-W', '--warnings=CATEGORY', Array, 'report the warnings falling in category') {|v| @diagnostic = v }
        o.separator ''
        o.separator 'Warning categories include:'
        o.separator '    conflicts-sr                     Shift/Reduce conflicts (enabled by default)'
        o.separator '    conflicts-rr                     Reduce/Reduce conflicts (enabled by default)'
        o.separator '    parameterizing-redefined         redefinition of parameterizing rule'
        o.separator '    all                              all warnings'
        o.separator '    none                             turn off all warnings'
        o.separator ''
        o.separator 'Error Recovery:'
        o.on('-e', 'enable error recovery') {|v| @options.error_recovery = true }
        o.separator ''
        o.separator 'Other options:'
        o.on('-V', '--version', "output version information and exit") {|v| puts "lrama #{Lrama::VERSION}"; exit 0 }
        o.on('-h', '--help', "display this help and exit") {|v| puts o; exit 0 }
        o.on_tail
        o.parse!(argv)
      end
    end

    ALIASED_REPORTS = { cex: :counterexamples }
    VALID_REPORTS = %i[states itemsets lookaheads solved counterexamples rules terms verbose]

    def validate_report(report)
      h = { grammar: true }
      return h if report.empty?
      return {} if report == ['none']
      if report == ['all']
        VALID_REPORTS.each { |r| h[r] = true }
        return h
      end

      report.each do |r|
        aliased = aliased_report_option(r)
        if VALID_REPORTS.include?(aliased)
          h[aliased] = true
        else
          raise "Invalid report option \"#{r}\"."
        end
      end

      return h
    end

    def aliased_report_option(opt)
      (ALIASED_REPORTS[opt.to_sym] || opt).to_sym
    end

    VALID_TRACES = %w[
      none locations scan parse automaton bitsets
      closure grammar rules actions resource
      sets muscles tools m4-early m4 skeleton time
      ielr cex all
    ]

    def validate_trace(trace)
      list = VALID_TRACES
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

    DIAGNOSTICS = %w[]
    HYPHENATED_DIAGNOSTICS = %w[conflicts-sr conflicts-rr parameterizing-redefined]

    def validate_diagnostic(diagnostic)
      h = { conflicts_sr: true, conflicts_rr: true }
      return h if diagnostic.nil?
      return {} if diagnostic.any? { |d| d == 'none' }
      return { all: true } if diagnostic.any? { |d| d == 'all' }

      diagnostic.each do |d|
        if DIAGNOSTICS.include?(d)
          h[d.to_sym] = true
        elsif HYPHENATED_DIAGNOSTICS.include?(d)
          h[d.gsub('-', '_').to_sym] = true
        else
          raise "Invalid diagnostic option \"#{d}\"."
        end
      end

      return h
    end
  end
end
