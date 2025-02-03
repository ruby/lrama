# frozen_string_literal: true

module Lrama
  class Command
    LRAMA_LIB = File.realpath(File.join(File.dirname(__FILE__)))
    STDLIB_FILE_PATH = File.join(LRAMA_LIB, 'grammar', 'stdlib.y')

    def run(argv)
      parser_options(argv)
      Lrama::Report::Profile::CallStack.report(@options.profile_opts[:call_stack]) do
        Lrama::Report::Profile::Memory.report(@options.profile_opts[:memory]) do
          _run
        end
      end
    end

    private

    def parser_options(argv)
      @options = OptionParser.new.parse(argv)
    rescue => e
      message = e.message
      message = message.gsub(/.+/, "\e[1m\\&\e[m") if Exception.to_tty?
      abort message
    end

    def _run
      Report::Duration.enable if @options.trace_opts[:time]

      text = @options.y.read
      @options.y.close if @options.y != STDIN
      begin
        grammar = Lrama::Parser.new(text, @options.grammar_file, @options.debug, @options.define).parse
        unless grammar.no_stdlib
          stdlib_grammar = Lrama::Parser.new(File.read(STDLIB_FILE_PATH), STDLIB_FILE_PATH, @options.debug).parse
          grammar.insert_before_parameterizing_rules(stdlib_grammar.parameterizing_rules)
        end
        grammar.prepare
        grammar.validate!
      rescue => e
        raise e if @options.debug
        message = e.message
        message = message.gsub(/.+/, "\e[1m\\&\e[m") if Exception.to_tty?
        abort message
      end
      states = Lrama::States.new(grammar, trace_state: (@options.trace_opts[:automaton] || @options.trace_opts[:closure]))
      states.compute
      states.compute_ielr if grammar.ielr_defined?
      context = Lrama::Context.new(states)

      if @options.report_file
        reporter = Lrama::StatesReporter.new(states)
        File.open(@options.report_file, "w+") do |f|
          reporter.report(f, **@options.report_opts)
        end
      end

      reporter = Lrama::TraceReporter.new(grammar)
      reporter.report(**@options.trace_opts)

      if @options.diagram
        File.open(@options.diagram_file, "w+") do |f|
          Lrama::Diagram.render(out: f, grammar: grammar)
        end
      end

      File.open(@options.outfile, "w+") do |f|
        Lrama::Output.new(
          out: f,
          output_file_path: @options.outfile,
          template_name: @options.skeleton,
          grammar_file_path: @options.grammar_file,
          header_file_path: @options.header_file,
          context: context,
          grammar: grammar,
          error_recovery: @options.error_recovery,
        ).render
      end

      logger = Lrama::Logger.new
      exit false unless Lrama::GrammarValidator.new(grammar, states, logger).valid?
      Lrama::Diagnostics.new(grammar, states, logger).run(@options.diagnostic)
    end
  end
end
