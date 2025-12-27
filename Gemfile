# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem "memory_profiler"
gem "pry"
gem "racc", "1.8.1"
gem "railroad_diagrams", "0.3.0"
gem "rake"
gem "rdoc"
gem "rspec"
gem "simplecov", require: false
gem "stackprof", platforms: [:ruby] # stackprof doesn't support Windows

# Recent steep requires Ruby >= 3.0.0.
# Then skip install on some CI jobs.
if !ENV['GITHUB_ACTION'] || ENV['INSTALL_STEEP'] == 'true'
  gem "rbs", "3.10.0", require: false
  gem "rbs-inline", require: false
  gem "steep", "1.10.0", require: false
end
