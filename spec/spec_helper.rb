require "simplecov"

SimpleCov.start do
  track_files "lib/**/*.rb"

  # Created Groups based on the folder structures
  add_group "Counterexamples", "lib/lrama/counterexamples"
  add_group "Grammar",         "lib/lrama/grammar"
  add_group "Lexer",           "lib/lrama/lexer"
  add_group "Parser",          "lib/lrama/parser"
  add_group "Report",          "lib/lrama/report"
  add_group "State",           "lib/lrama/state/"
  add_group "States",          "lib/lrama/states/"

  add_filter "spec/"

  enable_coverage :branch
end

require "lrama"

module RSpecHelper
  def fixture_path(file_name)
    File.expand_path("../fixtures/#{file_name}", __FILE__)
  end

  def sample_path(file_name)
    File.expand_path("../../sample/#{file_name}", __FILE__)
  end

  def exe_path(file_name)
    File.expand_path("../../exe/#{file_name}", __FILE__)
  end

  def windows?
    return /mswin|mingw|bccwin/ =~ RUBY_PLATFORM
  end
end

module LramaCustomMatchers
  class SymbolMatcher
    attr_reader :expected, :target

    def initialize(expected)
      @expected = expected
      @_failure_message = nil
    end

    def matches?(target)
      @target = target

      if !@expected.is_a?(Lrama::Grammar::Symbol)
        @_failure_message = "expected #{@expected.inspect} to be Lrama::Grammar::Symbol"
        return false
      end

      if !@target.is_a?(Lrama::Grammar::Symbol)
        @_failure_message = "expected #{@target.inspect} to be Lrama::Grammar::Symbol"
        return false
      end

      @expected.id == @target.id &&
      @expected.alias_name == @target.alias_name &&
      @expected.number == @target.number &&
      @expected.tag == @target.tag &&
      @expected.term == @target.term &&
      @expected.token_id == @target.token_id &&
      @expected.nullable == @target.nullable &&
      @expected.precedence == @target.precedence &&
      @expected.printer == @target.printer &&
      @expected.error_token == @target.error_token
    end

    def failure_message
      return @_failure_message if @_failure_message

      "expected #{@target.inspect} to match with #{@expected.inspect}"
    end

    def failure_message_when_negated
      return @_failure_message if @_failure_message

      "expected #{@target.inspect} not to match with #{@expected.inspect}"
    end
  end

  class SymbolsMatcher
    attr_reader :expected, :target

    def initialize(expected)
      @expected = expected
      @_failure_message = nil
    end

    def matches?(target)
      @target = target

      if !@expected.is_a?(Array)
        @_failure_message = "expected #{@expected.inspect} to be Array"
        return false
      end

      if !@target.is_a?(Array)
        @_failure_message = "expected #{@target.inspect} to be Array"
        return false
      end

      if @expected.count != @target.count
        @_failure_message = "expected the number of array to be same (#{@expected.count} != #{@target.count})"
        return false
      end

      @not_matched = []

      @expected.zip(@target).each do |expected, actual|
        matcher = SymbolMatcher.new(expected)
        unless matcher.matches?(actual)
          @not_matched << matcher
        end
      end

      @not_matched.empty?
    end

    def failure_message
      return @_failure_message if @_failure_message

      @not_matched.map(&:failure_message).join("\n")
    end

    def failure_message_when_negated
      return @_failure_message if @_failure_message

      @not_matched.map(&:failure_message_when_negated).join("\n")
    end
  end

  def match_symbol(expected)
    SymbolMatcher.new(expected)
  end

  def match_symbols(expected)
    SymbolsMatcher.new(expected)
  end
end

RSpec.configure do |config|
  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include(RSpecHelper)
  config.include(LramaCustomMatchers)

  # Allow to limit the run of the specs
  # NOTE: Please do not commit the filter option.
  # config.filter_run_when_matching :focus
end
