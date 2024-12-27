# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem "pry"
gem "racc", "1.8.1"
gem "rake"
gem "rspec"
gem "simplecov", require: false
gem "stackprof", platforms: [:ruby] # stackprof doesn't support Windows
gem "memory_profiler"

# Recent steep requires Ruby >= 3.0.0.
# Then skip install on some CI jobs.
if !ENV['GITHUB_ACTION'] || ENV['INSTALL_STEEP'] == 'true'
  gem "rbs", "3.7.0", require: false
  gem "rbs-inline", require: false
  gem "steep", "1.9.2", require: false
end
