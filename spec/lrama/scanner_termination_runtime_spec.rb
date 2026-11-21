# frozen_string_literal: true

require "open3"
require "tmpdir"

RSpec.describe "generated scanner termination" do
  def with_scanner(source)
    Dir.mktmpdir("lrama-scanner-termination") do |dir|
      compiler = ENV.fetch("COMPILER", "cc")
      cpp = compiler.include?("++")
      grammar = File.join(dir, "parser.y")
      output = File.join(dir, cpp ? "parser.cpp" : "parser.c")
      executable = File.join(dir, "parser")
      File.write(grammar, <<~GRAMMAR + source)
        %code provides {
          #include <stdio.h>
          #include <string.h>
          static size_t scanner_steps;
          static int yyerror(YYLTYPE *loc, const char *message) {
            (void)loc; (void)message; return 0;
          }
        }
        %define lr.type pslr
        %define api.pslr.lexer generated
      GRAMMAR
      Lrama::Command.new(["-o", output, grammar]).run
      source = File.read(output)
      expect(source).to include("int next_ss = yy_scanner_transition[ss][c];")
      source.sub!("int next_ss = yy_scanner_transition[ss][c];", "int next_ss = (scanner_steps++, yy_scanner_transition[ss][c]);")
      File.write(output, source)
      _out, err, status = Open3.capture3(compiler, cpp ? "-std=c++11" : "-std=c99", "-Werror", output, "-o", executable)
      expect(status.success?).to be(true), err
      out, err, status = Open3.capture3(executable)
      expect(status.success?).to be(true), out + err
      yield out if block_given?
    end
  end

  it "takes one scanner transition per shortest token in normal and fallback rows" do
    with_scanner(<<~'GRAMMAR') do |out|
      %token-pattern A /a+/
      %lex-prec A -s A
      %%
      start: %empty | start A;
      %%
      int main(void) {
        char input[8192];
        size_t lengths[] = {4096, 8192};
        size_t i, j;
        memset(input, 'a', sizeof input);
        for (i = 0; i < 2; i++) {
          scanner_steps = 0;
          yypslr_set_input(input, lengths[i]);
          if (yyparse()) return 1;
          printf("%lu ", (unsigned long)scanner_steps);
          scanner_steps = 0;
          for (j = 0; j < lengths[i]; j++) {
            yypslr_scan_result result;
            if (yy_pseudo_scan_result(YYFINAL, input + j, lengths[i] - j, &result) != A
                || result.length != 1 || !result.from_fallback) return 2;
          }
          printf("%lu\n", (unsigned long)scanner_steps);
        }
        return 0;
      }
    GRAMMAR
      expect(out).to eq("4096 4096\n8192 8192\n")
    end
  end

  it "keeps match lengths and source locations representable as int" do
    with_scanner(<<~'GRAMMAR')
      %code provides {
        #include <limits.h>
        /* Exercise the length boundary with a small input. */
        #undef INT_MAX
        #define INT_MAX 7
      }
      %locations
      %token-pattern A /a+/
      %token-pattern NL /\n/
      %%
      start: A NL;
      %%
      int main(void) {
        yypslr_scan_result result;
        int states[] = {0, YYFINAL};
        for (int i = 0; i < 2; i++) {
          if (yy_pseudo_scan_result(states[i], "aaaaaaa", 7, &result) != A || result.length != 7
              || result.from_fallback != i || result.is_character_token)
            return 1;
          if (yy_pseudo_scan_result(states[i], "aaaaaaaa", 8, &result) != YYUNDEF || result.length != 7
              || result.from_fallback != i || result.is_character_token)
            return 2;
          if (yy_pseudo_scan_result(states[i], "?", 1, &result) != YYUNDEF || result.length != 1
              || !result.from_fallback || !result.is_character_token)
            return 3;
        }
        YYSTYPE value;
        YYLTYPE location;
        yypslr_set_input("aaaaaaa\n\n\n\n\n\n\na", 15);
        if (yylex(&value, &location) != A || location.last_column != INT_MAX) return 4;
        for (int i = 0; i < 7; i++) {
          if (yylex(&value, &location) != NL) return 5;
        }
        if (yylex(&value, &location) != A || location.first_line != INT_MAX
            || location.first_column != 1 || location.last_column != 2) return 6;
        return 0;
      }
    GRAMMAR
  end

  it "keeps scanning for reachable replacements and normal matches after fallback wins" do
    with_scanner(<<~'GRAMMAR')
      %token-pattern A /a+/
      %token-pattern LONG /a+b/
      %token-pattern REPEAT /c+/
      %lex-prec A -s A
      %lex-prec A -~ LONG
      %%
      start: LONG | 'x' A | 'y' choice | REPEAT;
      choice: A | LONG;
      %%
      int main(void) {
        yypslr_scan_result result;
        int state, checked = 0;
        if (yy_pseudo_scan_result(0, "aaab", 4, &result) != LONG
            || result.length != 4 || result.from_fallback) return 1;
        if (yy_pseudo_scan_result(0, "ccc", 3, &result) != REPEAT
            || result.length != 3 || result.from_fallback) return 2;
        if (yy_pseudo_scan_result(YYFINAL, "aaab", 4, &result) != LONG
            || result.length != 4 || !result.from_fallback) return 3;
        for (state = 0; state < YYNSTATES; state++) {
          if (yy_pseudo_scan_result(state, "a", 1, &result) == A && !result.from_fallback
              && yy_pseudo_scan_result(state, "ab", 2, &result) == A) {
            scanner_steps = 0;
            if (yy_pseudo_scan_result(state, "aaaab", 5, &result) != A
                || result.length != 1 || result.from_fallback || scanner_steps != 1) return 4;
            checked = 1;
          }
        }
        if (!checked) return 5;
        yypslr_set_input("yaaab", 5);
        return yyparse();
      }
    GRAMMAR
  end
end
