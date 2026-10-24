# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem "memory_profiler"
gem "pry"
gem "racc", "1.8.1"
gem "railroad_diagrams", ">= 1.0.0"
gem "rake"
gem "rdoc"
gem "rexml", require: false
gem "rspec"
gem "simplecov", require: false
gem "stackprof", platforms: [:ruby] # stackprof doesn't support Windows

# Recent rbs and steep require Ruby >= 3.3.0.
# Then skip install on some CI jobs.
if !ENV['GITHUB_ACTION'] || ENV['INSTALL_STEEP'] == 'true'
  gem "rbs", "4.2.0", require: false
  gem "rbs-inline", require: false
  gem "steep", "2.1.0", require: false
end
