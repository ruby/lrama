require "bundler/gem_tasks"

namespace "build" do
  desc "build parser from parser.y by using Racc"
  task :racc_parser do
    sh "bundle exec racc parser.y --embedded -o lib/lrama/parser.rb"
  end

  desc "build parser for debugging"
  task :racc_verbose_parser do
    sh "bundle exec racc parser.y --embedded -o lib/lrama/parser.rb -t --log-file=parser.output"
  end
end
