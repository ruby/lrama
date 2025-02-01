# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem "pry"
gem "racc", "1.8.1"
gem "rake"
gem "rdoc"
gem "rspec"
gem "simplecov", require: false
gem "stackprof", platforms: [:ruby] # stackprof doesn't support Windows
gem "memory_profiler"

if RUBY_VERSION >= "3.1.0"
  gem "railroad_diagrams"
end

# Recent steep requires Ruby >= 3.0.0.
# Then skip install on some CI jobs.
if !ENV['GITHUB_ACTION'] || ENV['INSTALL_STEEP'] == 'true'
  gem "rbs", "3.8.1", require: false
  gem "rbs-inline", require: false
  gem "steep", "1.9.3", require: false
end
