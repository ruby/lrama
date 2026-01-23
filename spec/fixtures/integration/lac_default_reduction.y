%{
#include <stdio.h>
#include "lac_default_reduction.h"
#include "lac_default_reduction-lexer.h"

static int yyerror(YYLTYPE *loc, const char *str);
%}

%define parse.lac full
%define parse.error verbose

%token ID NUM

%locations

%%

program: stmt
       ;

stmt: ID '=' expr ';'
    | expr ';'
    ;

expr: expr '+' expr
    | expr '*' expr
    | NUM
    | ID
    ;

%%

static int yyerror(YYLTYPE *loc, const char *str) {
  (void)loc;
  printf("Error: %s\n", str);
  return 0;
}

int main(int argc, char *argv[]) {
  if (argc == 2) {
    yy_scan_string(argv[1]);
  }

  if (yyparse()) {
    return 1;
  }
  return 0;
}
