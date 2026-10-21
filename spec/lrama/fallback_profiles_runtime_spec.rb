# frozen_string_literal: true

require "open3"
require "tmpdir"

RSpec.describe "generated fallback scanner profiles" do
  it "resolves fallback precedence from the matches on the actual input path" do
    Dir.mktmpdir("lrama-fallback") do |dir|
      compiler = ENV.fetch("COMPILER", "cc")
      cpp = compiler.include?("++")
      grammar = File.join(dir, "parser.y")
      output = File.join(dir, cpp ? "parser.cpp" : "parser.c")
      executable = File.join(dir, "parser")
      File.write(grammar, <<~'GRAMMAR')
        %code provides {
          #include <stdio.h>
          #include <string.h>
          static int yyerror(YYLTYPE *loc, const char *message) {
            (void)loc; (void)message; return 0;
          }
        }
        %define lr.type pslr
        %define api.pslr.lexer generated
        %token-pattern A /aa/
        %token-pattern B /a+b/
        %token-pattern C /a+b/
        %token-pattern SHORT /d/
        %token-pattern LONG /d+/
        %token-pattern REPEAT /f+/
        %token-pattern SELF /e+/
        %lex-prec C << A
        %lex-prec B <- C
        %lex-prec A -~ B
        %lex-prec SHORT -s LONG
        %lex-prec SELF -s SELF
        %%
        start: 'x' A | 'y' B | 'z' C | 'u' SHORT | 'v' LONG | 'w' REPEAT | 't' SELF;
        %%
        int main(void) {
          const char *inputs[] = {"ab", "aab", "aaaaab", "aaaaa", "dddddd", "ffffff", "eeeeee"};
          const int expected[] = {C, B, B, A, SHORT, REPEAT, SELF};
          const int lengths[] = {2, 3, 6, 2, 1, 6, 1};
          int i;
          for (i = 0; i < 7; i++) {
            yypslr_scan_result result;
            int token = yy_pseudo_scan_result(0, inputs[i], strlen(inputs[i]), &result);
            if (token != expected[i] || result.length != lengths[i] || !result.from_fallback) {
              printf("%s: token %d (expected %d), length %d\n", inputs[i], token, expected[i], result.length);
              return 1;
            }
          }
          yypslr_set_input("yab", 3);
          if (yyparse()) return 2;
          yypslr_set_input("zaab", 4);
          return yyparse();
        }
      GRAMMAR
      Lrama::Command.new(["-o", output, grammar]).run
      _out, err, status = Open3.capture3(compiler, cpp ? "-std=c++11" : "-std=c99", "-Werror", output, "-o", executable)
      expect(status.success?).to be(true), err
      out, err, status = Open3.capture3(executable)
      expect(status.success?).to be(true), out + err
    end
  end
end
