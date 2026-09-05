/*
 * Integration test for PSLR pure mode (%define api.pslr.lexer generated).
 * The generated parser owns lexical analysis: no user yylex, layout is
 * skipped by the generated scan loop, and %token-action builds semantic
 * values from the matched lexeme.
 */

%{
#include <stdio.h>
#include <string.h>
#include "pslr_pure.h"

static int yyerror(YYLTYPE *loc, const char *str);
%}

%define lr.type pslr
%define api.pslr.lexer generated

%token NUM PLUS

%token-pattern NUM /[0-9]+/
%token-pattern PLUS /\+/
%token-pattern YYLAYOUT_WS /[ \t\r\n]+/

%token-action NUM {
  int yypslr_value = 0;
  int yypslr_i;
  for (yypslr_i = 0; yypslr_i < yyleng; yypslr_i++) {
    yypslr_value = yypslr_value * 10 + (yytext[yypslr_i] - '0');
  }
  yylval = yypslr_value;
}

%%

program: expr { printf("=> %d\n", $1); }
       ;

expr: NUM
    | expr PLUS NUM { $$ = $1 + $3; }
    ;

%%

static int yyerror(YYLTYPE *loc, const char *str)
{
  (void)loc;
  fprintf(stderr, "parse error: %s\n", str);
  return 0;
}

int main(int argc, char *argv[])
{
  const char *input = argc == 2 ? argv[1] : "";

  yypslr_set_input(input, strlen(input));

  if (yyparse()) {
    fprintf(stderr, "syntax error\n");
    return 1;
  }
  return 0;
}
