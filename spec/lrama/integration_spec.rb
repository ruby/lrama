require "tempfile"
require "open3"

RSpec.describe "integration" do
  module IntegrationHelper
    def test_rules(rules, input, expected, command_args: [], debug: false)
      cases = input.each_with_index.map do |(token, union, semantic_value), i|
        str = ""
        str << "    case #{i}:\n"
        str << "        yylval->#{union} = #{semantic_value};\n" if union && semantic_value
        str << "        return #{token};\n"
      end.join("\n")

      yydebug_macro = ''
      yydebug = ''

      if debug
        yydebug_macro = '#define YYDEBUG 1'
        yydebug = 'yydebug = 1;'
        command_args << "--report=all"
      end

      grammar = <<~Grammar
%{
#{yydebug_macro}
#include <stdio.h>

#include "test.h"

static int yylex(YYSTYPE *val, YYLTYPE *loc);
static int yyerror(YYLTYPE *loc, const char *str);
%}

#{rules}

// #{input}

int c = 0;

static int yylex(YYSTYPE *yylval, YYLTYPE *loc) {
    switch (c++) {
#{cases}
    default:
        // End of Input
        return -1;
    }
}

static int yyerror(YYLTYPE *loc, const char *str) {
    fprintf(stderr, "parse error: %s\\n", str);
    return 0;
}

int main() {
    #{yydebug}
    yyparse();
    return 0;
}

      Grammar

      Tempfile.create(%w[test .y]) do |f|
        f << grammar
        f.close
        c_path = File.dirname(f.path) + "/test.c"
        obj_path = File.dirname(f.path) + "/test"

        Lrama::Command.new(%W[-d -o #{c_path}] + command_args + %W[#{f.path}]).run

        `gcc -Wall #{c_path} -o #{obj_path}`

        result = Open3.popen3(obj_path) do |stdin, stdout, stderr, wait_thr|
          stdout.read
        end

        expect(result).to eq(expected)
      end
    end
  end

  include IntegrationHelper

  describe "calculator" do
    it "returns 9 for '(1+2)*3'" do
      # (1+2)*3 #=> 9
      input = [
        %w['('],
        %w[NUM val 1],
        %w['+'],
        %w[NUM val 2],
        %w[')'],
        %w['*'],
        %w[NUM val 3]
      ]

      test_rules(<<~Rules, input, "=> 9")
  %union {
      int val;
  }
  %token <val> NUM
  %type <val> expr
  %left '+' '-'
  %left '*' '/'

  %%

  program : { (void)yynerrs; }
       | expr { printf("=> %d", $1); }
       ;
  expr : NUM
       | expr '+' expr { $$ = $1 + $3; }
       | expr '-' expr { $$ = $1 - $3; }
       | expr '*' expr { $$ = $1 * $3; }
       | expr '/' expr { $$ = $1 / $3; }
       | '(' expr ')'  { $$ = $2; }
       ;

  %%
      Rules
    end
  end

  describe "named references" do
    it "returns 3 for '1 2 +" do
      # 1 2 + #=> 3
      input = [
        %w[NUM val 1],
        %w[NUM val 2],
        %w['+'],
      ]

      test_rules(<<~Rules, input, "=> 3")
  %union {
      int val;
  }
  %token <val> NUM
  %type <val> expr

  %%

  line: expr
          { (void)yynerrs; printf("=> %d", $expr); }
      ;

  expr[result]: NUM
              | expr[left] expr[right] '+'
                  { $result = $left + $right; }
              ;

  %%
      Rules
    end
  end

  # TODO: Add test case for "(1+2"
  describe "error_recovery" do
    it "returns 6 for '(1+)'" do
      # (1+) #=> 101
      # '100' is complemented
      input = [
        %w['('],
        %w[NUM val 1],
        %w['+'],
        %w[')'],
      ]

      test_rules(<<~Rules, input, "=> 101", command_args: %W[-e])
  %union {
      int val;
  }
  %token <val> NUM
  %type <val> expr
  %left '+' '-'
  %left '*' '/'

  %error-token {
    $$ = 100;
  } NUM

  %%

  program : { (void)yynerrs; }
       | expr { printf("=> %d", $1); }
       ;
  expr : NUM
       | expr '+' expr { $$ = $1 + $3; }
       | expr '-' expr { $$ = $1 - $3; }
       | expr '*' expr { $$ = $1 * $3; }
       | expr '/' expr { $$ = $1 / $3; }
       | '(' expr ')'  { $$ = $2; }
       ;

  %%
      Rules
    end
  end
end
