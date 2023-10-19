require "simplecov"

SimpleCov.start do
  track_files "lib/**/*.rb"

  # Created Groups based on the folder structures
  add_group "Grammar", "lib/lrama/grammar"
  add_group "Lexer", "lib/lrama/lexer"
  # add_group "Parser", "lib/lrama/parser"
  add_group "Report", "lib/lrama/report"
  add_group "State", "lib/lrama/state/"
  add_group "States", "lib/lrama/states/"

  add_filter "spec/"

  enable_coverage :branch
end

require "lrama"

RSpec.configure do |config|
  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Allow to limit the run of the specs
  # NOTE: Please do not commit the filter option.
  # config.filter_run_when_matching :focus
end

def fixture_path(file_name)
  File.expand_path("../fixtures/#{file_name}", __FILE__)
end

def exe_path(file_name)
  File.expand_path("../../exe/#{file_name}", __FILE__)
end
