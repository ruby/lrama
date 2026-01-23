%{
#include <stdio.h>
#include <stdlib.h>

static int new_syntax = 1;

int yylex(void);
void yyerror(const char *s);
%}

%token WIDGET ID NEW_ARG OLD_ARG

%%

program
    : widget
    ;

widget
    : {new_syntax}? WIDGET ID NEW_ARG
      { printf("New syntax widget\n"); }
    | {!new_syntax}? WIDGET ID OLD_ARG
      { printf("Old syntax widget\n"); }
    ;

%%

int yylex(void) {
    return 0;
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main(void) {
    return yyparse();
}
