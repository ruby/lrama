%{
#include <stdio.h>
#include <stdlib.h>

int yylex(void);
void yyerror(const char *s);
%}

%union {
    int i;
}

%token NUMBER
%precedence PRECEDENCE

%%

program:
    NUMBER
    ;

%%

int main(void) {
    printf("Parser ready. Enter expressions:\n");
    return yyparse();
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}
