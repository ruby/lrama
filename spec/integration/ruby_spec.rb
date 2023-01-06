require "tempfile"
require "open3"

RSpec.describe "integration" do
  describe "Ruby 3.2" do
    it do
      grammar_file_path = fixture_path("integration/ruby_3_2/parse.tmp.y")
      y = File.read(grammar_file_path)
      out = Tempfile.new
      header_out = Tempfile.new
      grammar = Lrama::Parser.new(y).parse
      states = Lrama::States.new(grammar)
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

      out, err, status = Open3.capture3("git diff --exit-code -U0 --ignore-all-space --no-index #{out.path} #{fixture_path("integration/ruby_3_2/y.tab.c")}")
      expect(status.exitstatus).to eq(0), out

      out, err, status = Open3.capture3("git diff --exit-code -U0 --ignore-all-space --no-index #{header_out.path} #{fixture_path("integration/ruby_3_2/y.tab.h")}")
      expect(status.exitstatus).to eq(0), out
    end
  end
end
