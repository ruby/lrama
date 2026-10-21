# frozen_string_literal: true

require "open3"
require "tmpdir"

RSpec.describe "declared error symbol runtime" do
  [false, true].each do |typed|
    it "compiles and recovers with a #{typed ? 'typed' : 'plain'} error token declaration" do
      Dir.mktmpdir("lrama-error-symbol") do |dir|
        compiler = ENV.fetch("COMPILER", "cc")
        cpp = compiler.include?("++")
        grammar = File.join(dir, "parser.y")
        output = File.join(dir, cpp ? "parser.cpp" : "parser.c")
        executable = File.join(dir, "parser")
        File.write(grammar, <<~GRAMMAR)
          #{typed ? '%union { int value; }' : ''}
          %token #{typed ? '<value>' : ''} error
          %token A
          %code provides {
            static int yyerror(YYLTYPE *loc, const char *message)
            {
              (void)loc;
              (void)message;
              return 0;
            }
            static int yylex(YYSTYPE *value)
            {
              static int index = 0;
              static int tokens[] = { YYUNDEF, A, YYEOF };
              (void)value;
              return tokens[index++];
            }
          }
          %%
          start: error A { #{typed ? '$1 = 7;' : ''} yyerrok; };
          %%
          int main(void) { return yyparse(); }
        GRAMMAR
        Lrama::Command.new(["-o", output, grammar]).run
        _out, err, status = Open3.capture3(compiler, cpp ? "-std=c++11" : "-std=c99", "-Werror", output, "-o", executable)
        expect(status.success?).to be(true), err
        _out, err, status = Open3.capture3(executable)
        expect(status.success?).to be(true), err
      end
    end
  end
end
