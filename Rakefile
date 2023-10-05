require "bundler/gem_tasks"

namespace "build" do
  desc "build parser from parser.y by using Racc"
  task :racc_parser do
    `bundle exec racc parser.y -o lib/lrama/new_parser.rb`
  end

  desc "build parser for debugging"
  task :racc_verbose_parser do
    `bundle exec racc parser.y -o lib/lrama/new_parser.rb -t -v`
  end
end
