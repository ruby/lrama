# frozen_string_literal: true

require "open3"
require "tmpdir"

RSpec.describe "repair token replay" do
  [["lalr", "full"], ["pslr", nil], ["lalr", "none"]].each do |type, lac|
    [false, true].each do |multiple|
      it "replays #{multiple ? 'multiple repairs' : 'a repair'} and the saved lookahead with #{type} LAC #{lac || 'default'}" do
        Dir.mktmpdir("lrama-repair-replay") do |dir|
          compiler = ENV.fetch("COMPILER", "cc")
          cpp = compiler.include?("++")
          grammar = File.join(dir, "parser.y")
          output = File.join(dir, cpp ? "parser.cpp" : "parser.c")
          executable = File.join(dir, "parser")
          File.write(grammar, <<~GRAMMAR)
            %define lr.type #{type}
            #{lac ? "%define parse.lac #{lac}" : ""}
            %locations
            %union { int value; }
            %token-pattern <value> A /a/
            %token-pattern <value> N /n/
            %token-pattern <value> B /b/
            #{multiple ? "%token-pattern <value> M /m/" : ""}
            %type <value> n #{multiple ? "m" : ""}
            %error-token {
              $$ = 22;
              @$.first_line = @$.last_line = 3;
              @$.first_column = 4;
              @$.last_column = 5;
            } N
            #{multiple ? "%error-token { $$ = 44; @$.first_line = @$.last_line = 4; @$.first_column = 5; @$.last_column = 6; } M" : ""}
            %code provides {
              static int reads = 0;
              static int errors = 0;
              static int accepted = 0;
              static int yyerror(YYLTYPE *location, const char *message) {
                (void)location;
                (void)message;
                errors++;
                return 0;
              }
              static int yylex(YYSTYPE *value, YYLTYPE *location) {
                const int tokens[] = { A, B, YYEOF };
                const int values[] = { 11, 33, 0 };
                int index = reads < 3 ? reads : 2;
                value->value = values[index];
                location->first_line = location->last_line = index ? 5 : 1;
                location->first_column = index ? 6 : 2;
                location->last_column = index ? 7 : 3;
                reads++;
                return tokens[index];
              }
            }
            %%
            start: A n #{multiple ? "m" : ""} B {
              if ($1 != 11 || $2 != 22 || $#{multiple ? 4 : 3} != 33) YYABORT;
              if (@2.first_line != 3 || @2.first_column != 4 || @2.last_line != 3 || @2.last_column != 5) YYABORT;
              if (@#{multiple ? 4 : 3}.first_line != 5 || @#{multiple ? 4 : 3}.first_column != 6
                  || @#{multiple ? 4 : 3}.last_line != 5 || @#{multiple ? 4 : 3}.last_column != 7) YYABORT;
              #{multiple ? "if ($3 != 44 || @3.first_line != 4 || @3.first_column != 5 || @3.last_line != 4 || @3.last_column != 6) YYABORT;" : ""}
              accepted++;
            };
            n: N;
            #{multiple ? "m: M;" : ""}
            %%
            int main(void) {
              return yyparse() || accepted != 1 || errors != 1 || reads != 3;
            }
          GRAMMAR
          Lrama::Command.new(["-e", "-o", output, grammar]).run
          _out, err, status = Open3.capture3(compiler, cpp ? "-std=c++11" : "-std=c99", "-Werror", output, "-o", executable)
          expect(status.success?).to be(true), "#{status}: #{err}"
          _out, err, status = Open3.capture3(executable)
          expect(status.success?).to be(true), "#{status}: #{err}"
        end
      end
    end
  end
end
