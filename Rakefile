# frozen_string_literal: true

require "bundler/gem_tasks"

namespace "build" do
  desc "build parser from parser.y"
  task :parser do
    sh "bundle exec racc parser.y --embedded -o lib/lrama/parser.rb -t --log-file=parser.output"
  end
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end
task :spec => "build:parser"

require "rdoc/task"
RDoc::Task.new do |rdoc|
  rdoc.title = "Lrama Documentation"
  rdoc.main = "Index.md"
  rdoc.rdoc_dir = "_site"
end

desc "steep check"
task :steep do
  sh "bundle exec steep check"
end
task :steep => :rbs_inline

desc "Run rbs-inline"
task :rbs_inline do
  sh "bundle exec rbs-inline --output lib/"
end

task default: %i[spec steep]
