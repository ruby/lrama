require "tempfile"
require "open3"

RSpec.describe "integration" do
  def generate_and_compare(version)
    grammar_file_path = fixture_path("integration/#{version}/parse.tmp.y")
    warning = Lrama::Warning.new
    y = File.read(grammar_file_path)
    out = Tempfile.new
    header_out = Tempfile.new
    grammar = Lrama::Parser.new(y).parse
    states = Lrama::States.new(grammar, warning)
    states.compute
    context = Lrama::Context.new(states)
    Lrama::Output.new(
      out: out,
      output_file_path: "y.tab.c",
      template_name: "bison/yacc.c",
      grammar_file_path: "parse.tmp.y",
      header_out: header_out,
      header_file_path: "y.tab.h",
      context: context,
      grammar: grammar,
    ).render
    out.close
    header_out.close

    {"y.tab.c"=>out.path, "y.tab.h"=>header_out.path}.each do |expected, actual|
      content = File.read(fixture_path("integration/#{version}/#{expected}"))
      content.sub!(/\A.*\KGNU Bison \d+(?:\.\d)*/) {"Lrama #{Lrama::VERSION}"}
      Tempfile.create(expected) do |tmp|
        tmp.write(content)
        out, err, status = Open3.capture3("git diff --exit-code -U0 --ignore-all-space --no-index #{actual} #{tmp.path}")
        expect(status.success?).to be_truthy, out
      end
    end
  end

  describe "Ruby 3.2" do
    it do
      generate_and_compare("ruby_3_2_0")
    end
  end

  describe "Ruby 3.1" do
    it do
      generate_and_compare("ruby_3_1_0")
    end
  end

  describe "Ruby 3.0" do
    it do
      generate_and_compare("ruby_3_0_5")
    end
  end
end
