# frozen_string_literal: true

require_relative "differential"
require "open3"

RSpec.describe IELRDifferential do
  around do |example|
    Dir.mktmpdir("ielr differential ") do |directory|
      @directory = directory
      example.run
    end
  end

  def capture(name, source, timeout: 5, **options)
    checkout = File.join(@directory, name)
    FileUtils.mkdir_p(File.join(checkout, "exe"))
    File.write(File.join(checkout, "exe/lrama"), source)
    described_class.capture(checkout, "%%\nstart: 'a';\n", File.join(@directory, "#{name} output"), timeout: timeout, **options)
  end

  let(:source) do
    <<~'RUBY'
      File.binwrite("parser.c", "#line 1 #{File.expand_path('grammar.y').inspect}\n")
      File.binwrite("parser.output", "State 0\n")
      $stderr.binmode
      warn "#{__FILE__}: warning"
    RUBY
  end

  it "normalizes checkout and output paths without changing other bytes" do
    baseline = capture("baseline", source)
    candidate = capture("candidate", source)

    expect(baseline).to eq(candidate)
    expect(baseline.fetch("parser.c")).to eq("#line 1 \"<output>/grammar.y\"\n")
    expect(baseline.fetch("stderr")).to eq("<checkout>/exe/lrama: warning\n")
    expect(baseline.fetch("status")).to eq("exit 0\n")
  end

  it "includes time-dependent counterexample searches only when requested" do
    source = 'File.binwrite("parser.output", ARGV.find { |arg| arg.start_with?("--report=") })'
    baseline = capture("baseline", source)
    expect(baseline.fetch("parser.output")).to eq("--report=states,itemsets,lookaheads,solved,rules,terms,verbose")

    candidate = capture("candidate", source, counterexamples: true)
    expect(candidate.fetch("parser.output")).to eq("--report=all")
  end

  {
    "parser.c" => 'File.write("parser.c", "changed\n")',
    "parser.output" => 'File.write("parser.output", "changed\n")',
    "stderr" => 'warn "changed"',
    "status" => 'exit 1',
  }.each do |artifact, change|
    it "detects a change in #{artifact}" do
      baseline = capture("baseline", source)
      candidate = capture("candidate", "#{source}\n#{change}\n")

      expect(described_class.differences(baseline, candidate)).to eq([artifact])
    end
  end

  it "distinguishes missing output from an empty file after a failure" do
    baseline = capture("baseline", 'exit 1')
    candidate = capture("candidate", 'File.write("parser.c", ""); exit 1')

    expect(baseline.fetch("parser.c")).to be_nil
    expect(described_class.differences(baseline, candidate)).to eq(["parser.c"])
  end

  it "keeps matching nonzero exits visible" do
    baseline = capture("baseline", 'warn "known failure"; exit 1')
    candidate = capture("candidate", 'warn "known failure"; exit 1')

    expect(described_class.differences(baseline, candidate)).to be_empty
    expect(baseline.fetch("status")).to eq("exit 1\n")
  end

  it "does not treat two timeouts as matching results" do
    baseline = capture("baseline", "sleep 30", timeout: 0.1)
    candidate = capture("candidate", "sleep 30", timeout: 0.1)

    expect(described_class.differences(baseline, candidate)).to include("status")
    expect(baseline.fetch("status")).to eq("timeout\n")
  end

  it "does not treat two signal terminations as matching results" do
    skip "Signal status is not available on Windows" if windows?
    baseline = capture("baseline", 'Process.kill("KILL", Process.pid)')
    candidate = capture("candidate", 'Process.kill("KILL", Process.pid)')

    expect(described_class.differences(baseline, candidate)).to include("status")
    expect(baseline.fetch("status")).to eq("signal 9\n")
  end

  it "does not inherit Ruby load-path overrides from the harness process" do
    rubyopt, rubylib = ENV.values_at("RUBYOPT", "RUBYLIB")
    File.write(File.join(@directory, "poison.rb"), "abort 'wrong library'\n")
    ENV["RUBYOPT"] = "-rpoison"
    ENV["RUBYLIB"] = @directory

    expect(capture("baseline", source).fetch("status")).to eq("exit 0\n")
  ensure
    ENV["RUBYOPT"], ENV["RUBYLIB"] = rubyopt, rubylib
  end

  it "compares committed revisions, preserves differences, and ignores uncommitted edits" do
    repository = File.join(@directory, "repository")
    FileUtils.mkdir_p(File.join(repository, "exe"))
    git = lambda do |*args|
      output, status = Open3.capture2e("git", "-C", repository, *args)
      raise output unless status.success?
      output.strip
    end
    git.call("init")
    git.call("config", "user.name", "IELR test")
    git.call("config", "user.email", "ielr@example.invalid")
    File.write(File.join(repository, "exe/lrama"), source)
    git.call("add", ".")
    git.call("-c", "commit.gpgsign=false", "commit", "-m", "Baseline")
    baseline = git.call("rev-parse", "HEAD")
    File.write(File.join(repository, "exe/lrama"), "#{source}\nFile.write('parser.output', 'changed')\n")
    git.call("add", ".")
    git.call("-c", "commit.gpgsign=false", "commit", "-m", "Change report")
    File.write(File.join(repository, "exe/lrama"), "raise 'uncommitted'\n")

    result = nil
    expect {
      result = described_class.main([baseline, "--count=0", "--counterexamples"], repository: repository)
    }.to output(/DIFF .*parser.output.*\n.*[1-9]\d* differences/m).to_stdout
    expect(result).to eq(1)
    saved = Dir[File.join(Dir.tmpdir, "lrama-ielr-*", "fixture-*", "candidate", "parser.output")]
    expect(saved).not_to be_empty
    expect(saved.any? { |path| File.read(path) == "changed" }).to be(true)

    expect {
      result = described_class.main([baseline, baseline, "--count=0"], repository: repository)
    }.to output(/0 differences/).to_stdout
    expect(result).to eq(0)
    expect(File.read(File.join(repository, "exe/lrama"))).to eq("raise 'uncommitted'\n")
  end

  it "rejects invalid arguments and unknown revisions" do
    [["HEAD", "--count=-1"], ["HEAD", "--timeout=0"], ["unknown-ielr-revision", "--count=0"]].each do |args|
      result = nil
      expect { result = described_class.main(args) }.to output(/error:/).to_stderr
      expect(result).to eq(2)
    end
  end
end
