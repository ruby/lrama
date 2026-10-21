# frozen_string_literal: true

require "open3"
require "tmpdir"

RSpec.describe "repair searches through default reductions" do
  rules = {
    "one reduction" => ["a: A { actions++; $$ = $1; };", 1],
    "chained reductions" => ["a: b { actions++; $$ = $1; }; b: c { actions++; $$ = $1; }; c: A { actions++; $$ = $1; };", 3],
    "nullable reductions" => ["a: A empty { actions++; $$ = $1 + $2; }; empty: %empty { actions++; $$ = 0; };", 2],
    "nullable reductions requiring stack growth" => ["a: A #{(['empty'] * 110).join(' ')} { actions++; $$ = $1; }; empty: %empty { actions++; $$ = 0; };", 111]
  }

  [["lalr", "full"], ["pslr", nil], ["lalr", "none"]].each do |type, lac|
    rules.each do |description, (productions, action_count)|
      it "inserts a missing token after #{description} with #{type} LAC #{lac || 'default'}" do
        Dir.mktmpdir("lrama-repair-default-reduction") do |dir|
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
            %token-pattern <value> B /b/
            %type <value> a #{description == "chained reductions" ? "b c" : ""} #{productions.include?("empty:") ? "empty" : ""}
            %error-token {
              $$ = 29;
              @$.first_line = @$.last_line = 3;
              @$.first_column = 4;
              @$.last_column = 5;
            } B
            %code provides {
              static int reads = 0;
              static int errors = 0;
              static int actions = 0;
              static int accepted = 0;
              static int yyerror(YYLTYPE *location, const char *message) {
                (void)location;
                (void)message;
                errors++;
                return 0;
              }
              static int yylex(YYSTYPE *value, YYLTYPE *location) {
                value->value = 17;
                location->first_line = location->last_line = 1;
                location->first_column = 1;
                location->last_column = 2;
                return reads++ ? YYEOF : A;
              }
            }
            %%
            start: a B {
              if ($1 != 17 || $2 != 29 || actions != #{action_count}) YYABORT;
              if (@1.first_line != 1 || @1.first_column != 1) YYABORT;
              if (@2.first_line != 3 || @2.first_column != 4 || @2.last_line != 3 || @2.last_column != 5) YYABORT;
              accepted++;
            };
            #{productions}
            %%
            int main(void) {
              return yyparse() || accepted != 1 || errors != 1 || reads != 2;
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
