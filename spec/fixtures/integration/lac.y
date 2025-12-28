%{
#include <stdio.h>
#include <stdlib.h>

int yylex(YYSTYPE *yylval, YYLTYPE *yylloc);
void yyerror(YYLTYPE *yylloc, const char *s);
%}

%define parse.lac full
%define parse.error verbose
%locations

%token NUMBER

%left '+' '-'
%left '*' '/'

%%

program: expr
       ;

expr: expr '+' expr
    | expr '-' expr
    | expr '*' expr
    | expr '/' expr
    | '(' expr ')'
    | NUMBER
    ;

%%

void yyerror(YYLTYPE *yylloc, const char *s) {
  (void)yylloc;
  fprintf(stderr, "Error: %s\n", s);
}

int yylex(YYSTYPE *yylval, YYLTYPE *yylloc) {
  (void)yylval;
  (void)yylloc;
  return 0;
}

int main() {
  return yyparse();
}
