/*
 * Integration test for parser without %union directive
 * This test verifies that lrama can generate parsers without %union,
 * just like Bison does (YYSTYPE defaults to int).
 */

%{
#include <stdio.h>
#include "no_union.h"
#include "no_union-lexer.h"

static int yyerror(YYLTYPE *loc, const char *str);
%}

%token NUMBER

%locations

%%

program: /* empty */
       | expr { printf("=> %d\n", $1); }
       ;

expr: NUMBER
    | expr '+' NUMBER { $$ = $1 + $3; }
    | expr '-' NUMBER { $$ = $1 - $3; }
    ;

%%

static int yyerror(YYLTYPE *loc, const char *str)
{
  fprintf(stderr, "%d.%d-%d.%d: %s\n", loc->first_line, loc->first_column, loc->last_line, loc->last_column, str);
  return 0;
}

int main(int argc, char *argv[])
{
  if (argc == 2) {
    yy_scan_string(argv[1]);
  }

  if (yyparse()) {
    fprintf(stderr, "syntax error\n");
    return 1;
  }
  return 0;
}
