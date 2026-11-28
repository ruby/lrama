# frozen_string_literal: true

require "open3"
require "tmpdir"

RSpec.describe "PSLR output with unreachable split states" do
  {
    "partially populated reduction lookaheads" => {
      patterns: "%token-pattern A /a/\n%token-pattern C /c/",
      rules: "start: y; x: A A y | A x y; y: %empty | C x x | A;",
      valid: ["", "a"],
      invalid: ["aa", "c"]
    },
    "unreachable lookahead-source transitions" => {
      patterns: "%token-pattern A /a/\n%token-pattern B /b/\n%token-pattern C /c/",
      rules: "start: C x y; x: A | B y; y: A x B | A B x;",
      valid: ["caaab", "caaba", "cbaabaab"],
      invalid: ["", "caab"]
    }
  }.each do |label, example|
    [nil, "states", "pslr"].each do |report|
      it "generates and runs #{label} with #{report || 'no'} report" do
        Dir.mktmpdir("lrama-split-state") do |dir|
          compiler = ENV.fetch("COMPILER", "cc")
          cpp = compiler.include?("++")
          grammar = File.join(dir, "parser.y")
          output = File.join(dir, cpp ? "parser.cpp" : "parser.c")
          report_file = File.join(dir, "parser.output")
          executable = File.join(dir, "parser")
          File.write(grammar, <<~GRAMMAR)
            %code provides {
              #include <string.h>
              static int yyerror(YYLTYPE *loc, const char *message)
              {
                (void)loc;
                (void)message;
                return 0;
              }
            }
            %define lr.type pslr
            %define api.pslr.lexer generated
            #{example.fetch(:patterns)}
            %%
            #{example.fetch(:rules)}
            %%
            int main(int argc, char **argv) {
              if (argc != 2) return 2;
              yypslr_set_input(argv[1], (int)strlen(argv[1]));
              return yyparse();
            }
          GRAMMAR
          options = ["-o", output, grammar]
          options += ["--report=#{report}", "--report-file=#{report_file}"] if report
          Lrama::Command.new(options).run
          if report
            expect(File.read(report_file)).to include(report == "states" ? "State 0" : "PSLR Summary")
          end
          _out, err, status = Open3.capture3(compiler, cpp ? "-std=c++11" : "-std=c99", "-Werror", output, "-o", executable)
          expect(status.success?).to be(true), err
          example.fetch(:valid).each do |input|
            _out, err, status = Open3.capture3(executable, input)
            expect(status.exitstatus).to eq(0), "rejected #{input.inspect}: #{err}"
          end
          example.fetch(:invalid).each do |input|
            _out, err, status = Open3.capture3(executable, input)
            expect(status.exitstatus).to eq(1), "accepted #{input.inspect}: #{err}"
          end
        end
      end
    end
  end
end
