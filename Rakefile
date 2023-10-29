require "bundler/gem_tasks"

namespace "build" do
  desc "build parser from parser.y"
  task :parser do
    sh "bundle exec racc parser.y --embedded -o lib/lrama/parser.rb -t --log-file=parser.output"
  end
end
