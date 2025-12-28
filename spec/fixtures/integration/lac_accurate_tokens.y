%{
#include <stdio.h>
#include "lac_accurate_tokens.h"
#include "lac_accurate_tokens-lexer.h"

static int yyerror(YYLTYPE *loc, const char *str);
%}

%define parse.lac full
%define parse.error verbose

%token IF THEN ELSE WHILE DO ID NUM

%left '+' '-'
%left '*' '/'

%locations

%%

program: stmt_list
       ;

stmt_list: stmt
         | stmt_list stmt
         ;

stmt: if_stmt
    | while_stmt
    | expr
    ;

if_stmt: IF expr THEN stmt
       | IF expr THEN stmt ELSE stmt
       ;

while_stmt: WHILE expr DO stmt
          ;

expr: expr '+' expr
    | expr '-' expr
    | expr '*' expr
    | expr '/' expr
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
