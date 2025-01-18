# frozen_string_literal: true

require_relative "lib/lrama/version.rb"

Gem::Specification.new do |spec|
  spec.name          = "lrama"
  spec.version       = Lrama::VERSION
  spec.authors       = ["Yuichiro Kaneko"]
  spec.email         = ["spiketeika@gmail.com"]

  spec.summary       = "LALR (1) parser generator written by Ruby"
  spec.description   = "LALR (1) parser generator written by Ruby"
  spec.homepage      = "https://github.com/ruby/lrama"
  # See LEGAL.md file for detail
  spec.license       = "GPL-3.0-or-later"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features|sample)/}) }
  end

  spec.metadata["homepage_uri"]      = spec.homepage
  spec.metadata["source_code_uri"]   = spec.homepage
  spec.metadata["documentation_uri"] = "https://ruby.github.io/lrama/"
  spec.metadata["changelog_uri"]     = "#{spec.homepage}/releases"
  spec.metadata["bug_tracker_uri"]   = "#{spec.homepage}/issues"

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
