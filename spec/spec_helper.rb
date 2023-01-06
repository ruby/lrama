require "lrama"

RSpec.configure do |config|
  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def fixture_path(file_name)
  File.expand_path("../fixtures/#{file_name}", __FILE__)
end
