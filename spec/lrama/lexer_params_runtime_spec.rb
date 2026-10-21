# frozen_string_literal: true

require "open3"
require "tmpdir"

RSpec.describe "PSLR lexer parameter runtime" do
  def run_parser(source, lexer: nil)
    Dir.mktmpdir("lrama-lexer-params") do |dir|
      compiler = ENV.fetch("COMPILER", "cc")
      cpp = compiler.include?("++")
      grammar = File.join(dir, "parser.y")
      output = File.join(dir, cpp ? "parser.cpp" : "parser.c")
      executable = File.join(dir, "parser")
      File.write(grammar, source)
      Lrama::Command.new(["-d", "-o", output, grammar]).run
      sources = [output]
      if lexer
        lexer_path = File.join(dir, cpp ? "lexer.cpp" : "lexer.c")
        File.write(lexer_path, lexer)
        sources << lexer_path
      end
      _out, err, status = Open3.capture3(compiler, cpp ? "-std=c++11" : "-std=c99", "-Werror", *sources, "-o", executable)
      expect(status.success?).to be(true), err
      _out, err, status = Open3.capture3(executable)
      expect(status.success?).to be(true), "exit #{status.exitstatus}: #{err}"
    end
  end

  %w[counter token input result parser_state input_len Token].product([false, true]).each do |parameter, locations|
    it "passes lexer parameter #{parameter} to token, layout and EOF actions #{locations ? 'with' : 'without'} locations" do
      run_parser(<<~GRAMMAR)
        %define lr.type pslr
        %define api.pslr.lexer generated
        #{locations ? '%locations' : ''}
        %lex-param {int *#{parameter}}
        %parse-param {int *#{parameter}}
        %code provides {
          static int yyerror(YYLTYPE *loc, int *counter, const char *message)
          { (void)loc; (void)counter; (void)message; return 0; }
        }
        %token-pattern A /a/
        %token-pattern YYLAYOUT_WS / +/
        %token-action A { yylval = ++*#{parameter}; }
        %token-action YYLAYOUT_WS { ++*#{parameter}; }
        %token-action YYEOF { ++*#{parameter}; }
        %%
        start: A { if ($1 != 2) YYABORT; };
        %%
        int main(void) {
          int counter = 0;
          yypslr_set_input(" a ", 3);
          return yyparse(&counter) || counter != 4;
        }
      GRAMMAR
    end
  end

  it "passes a lexer parameter to the EOF action without scanner patterns" do
    run_parser(<<~GRAMMAR)
      %define lr.type pslr
      %define api.pslr.lexer generated
      %lex-param {int *counter}
      %parse-param {int *counter}
      %code provides {
        static int yyerror(YYLTYPE *loc, int *counter, const char *message)
        { (void)loc; (void)counter; (void)message; return 0; }
      }
      %token-action YYEOF { ++*counter; }
      %%
      start: %empty;
      %%
      int main(void) {
        int counter = 0;
        yypslr_set_input("", 0);
        return yyparse(&counter) || counter != 1;
      }
    GRAMMAR
  end

  it "forwards a separately compiled bridge lexer's parameter through the layout macro" do
    lexer = <<~C_CODE
      #include "parser.h"

      int yylex(YYSTYPE *value, struct lexer_state *Result) {
        yypslr_scan_result result;
        int token = YYPSLR_SCAN_WITH_LAYOUT(Result->current_state, &Result->input, &Result->remaining, value, &result);
        if (token != YYEOF && token != YYEMPTY) {
          Result->input += result.length;
          Result->remaining -= result.length;
        }
        return token;
      }
    C_CODE
    run_parser(<<~GRAMMAR, lexer: lexer)
      %define lr.type pslr
      %define api.pslr.state-member current_state
      %lex-param {struct lexer_state *Result}
      %parse-param {struct lexer_state *Result}
      %code requires {
        #include <stddef.h>
        struct lexer_state { int current_state; int counter; const char *input; size_t remaining; };
      }
      %code provides {
        int yylex(YYSTYPE *value, struct lexer_state *p);
        int yyerror(YYLTYPE *loc, struct lexer_state *p, const char *message);
      }
      %token-pattern A /a/
      %token-pattern YYLAYOUT_WS / +/
      %token-action A { yylval = ++Result->counter; }
      %token-action YYLAYOUT_WS { ++Result->counter; }
      %token-action YYEOF { ++Result->counter; }
      %%
      start: A { if ($1 != 2) YYABORT; };
      %%
      int yyerror(YYLTYPE *loc, struct lexer_state *p, const char *message)
      { (void)loc; (void)p; (void)message; return 0; }

      int main(void) {
        struct lexer_state state = { 0, 0, " a ", 3 };
        return yyparse(&state) || state.counter != 4;
      }
    GRAMMAR
  end
end
