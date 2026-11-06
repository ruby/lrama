# frozen_string_literal: true

require "fileutils"
require "open3"
require "optparse"
require "rbconfig"
require "tmpdir"
require_relative "grammar"

module IELRDifferential
  ARTIFACTS = %w[parser.c parser.output stderr status].freeze

  def self.capture(checkout, grammar, directory, timeout:, counterexamples: false)
    FileUtils.mkdir_p(File.dirname(directory))
    Dir.mkdir(directory)
    File.binwrite(File.join(directory, "grammar.y"), grammar)
    reports = counterexamples ? "all" : "states,itemsets,lookaheads,solved,rules,terms,verbose"
    command = [RbConfig.ruby, File.join(checkout, "exe/lrama"), "-o", "parser.c",
               "--report=#{reports}", "--report-file=parser.output", "grammar.y"]
    # bundle exec must not make either revision load the working tree's library.
    env = { "RUBYOPT" => nil, "RUBYLIB" => nil, "BUNDLE_GEMFILE" => nil }
    pid = Process.spawn(env, *command, chdir: directory,
                       out: File.join(directory, "stdout"), err: File.join(directory, "stderr"))
    waiter = Process.detach(pid)
    begin
      if waiter.join(timeout)
        status = waiter.value
        result = status.signaled? ? "signal #{status.termsig}" : "exit #{status.exitstatus}"
      else
        result = "timeout"
      end
    ensure
      if waiter.alive?
        begin
          Process.kill("KILL", pid)
        rescue Errno::ESRCH
        end
        waiter.join
      end
    end
    File.binwrite(File.join(directory, "status"), "#{result}\n")

    prefixes = {}
    { checkout => "<checkout>", directory => "<output>" }.each do |root, replacement|
      [File.expand_path(root), File.realpath(root)].each { |prefix| prefixes["#{prefix}/"] = "#{replacement}/" }
    end
    ARTIFACTS.each_with_object({}) do |name, artifacts|
      path = File.join(directory, name)
      content = File.file?(path) ? File.binread(path) : nil
      if content
        prefixes.sort_by { |prefix, _| -prefix.length }.each { |prefix, replacement| content = content.gsub(prefix, replacement) }
      end
      artifacts[name] = content
    end
  end

  def self.differences(baseline, candidate)
    ARTIFACTS.select do |name|
      baseline.fetch(name) != candidate.fetch(name) ||
        (name == "status" && [baseline[name], candidate[name]].any? { |status| status == "timeout\n" || status.start_with?("signal ") })
    end
  end

  def self.command!(*command)
    output, status = Open3.capture2e(*command)
    raise "#{command.first} failed: #{output}" unless status.success?
    output.strip
  end

  def self.export(repository, revision, directory)
    commit = command!("git", "-C", repository, "rev-parse", "--verify", "--end-of-options", "#{revision}^{commit}")
    Dir.mkdir(directory)
    archive = "#{directory}.tar"
    command!("git", "-C", repository, "archive", "--format=tar", "--output=#{archive}", commit)
    command!("tar", "-xf", File.basename(archive), "-C", File.basename(directory), chdir: File.dirname(directory))
    File.unlink(archive)
    commit
  end

  def self.main(argv, repository: File.expand_path("../..", __dir__))
    count = 250
    seed = 0
    timeout = 30
    counterexamples = false
    grammars = [File.expand_path("../fixtures/integration/ielr.y", __dir__)]
    grammars.concat(Dir[File.expand_path("../fixtures/ielr/*.y", __dir__)].sort)
    options = OptionParser.new do |parser|
      parser.banner = "Usage: ruby spec/ielr/differential.rb BASE [TARGET=HEAD] [options]"
      parser.on("--count=N", Integer, "Number of random grammars (default: 250)") { |value| count = value }
      parser.on("--seed=N", Integer, "First random seed (default: 0)") { |value| seed = value }
      parser.on("--timeout=SECONDS", Float, "Time limit per invocation (default: 30)") { |value| timeout = value }
      parser.on("--counterexamples", "Include time-dependent counterexamples (--report=all)") { counterexamples = true }
      parser.on("--grammar=PATH", "Also compare this grammar (repeatable)") { |path| grammars << File.expand_path(path) }
      parser.on("-h", "--help") { puts parser; return 0 }
    end
    refs = options.parse(argv)
    raise ArgumentError, options.banner unless (1..2).include?(refs.length)
    raise ArgumentError, "count must be nonnegative and timeout must be positive" unless count >= 0 && timeout > 0 && timeout.finite?

    directory = Dir.mktmpdir("lrama-ielr-")
    checkouts = %w[baseline candidate].map { |name| File.join(directory, name) }
    commits = [refs[0], refs[1] || "HEAD"].zip(checkouts).map { |ref, checkout| export(repository, ref, checkout) }
    puts "Comparing #{commits.join(' -> ')}"
    puts "Artifacts: #{directory}"
    inputs = grammars.map.with_index { |path, index| ["fixture-#{index}-#{File.basename(path, '.y')}", File.binread(path)] }
    count.times { |index| inputs << ["seed-#{seed + index}", IELRGrammar.generate(seed + index)] }
    mismatches = failures = 0
    inputs.each do |name, grammar|
      results = checkouts.each_with_index.map do |checkout, index|
        capture(checkout, grammar, File.join(directory, name, index.zero? ? "baseline" : "candidate"),
                timeout: timeout, counterexamples: counterexamples)
      end
      changed = differences(*results)
      if !changed.empty?
        mismatches += 1
        puts "DIFF #{name}: #{changed.join(', ')}"
      elsif results.first.fetch("status") != "exit 0\n"
        failures += 1
        puts "MATCHED FAILURE #{name}: #{results.first.fetch('status').strip}"
      end
    end
    puts "#{inputs.length} grammars, #{mismatches} differences, #{failures} matching nonzero exits"
    mismatches.zero? ? 0 : 1
  rescue OptionParser::ParseError, ArgumentError, RuntimeError, SystemCallError => error
    warn "error: #{error.message}"
    2
  end
end

exit IELRDifferential.main(ARGV) if $PROGRAM_NAME == __FILE__
