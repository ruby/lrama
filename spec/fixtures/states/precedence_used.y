%{
#include <stdio.h>
#include <stdlib.h>

int yylex(void);
void yyerror(const char *s);
%}

%union {
    int i;
}

%token <i> NUMBER
%token MINUS

%nterm <i> expr

%left MINUS
%right UMINUS    /* Unary minus */

%%

input:
    %empty
    | input line
    ;

line:
    expr '\n' { printf("Result: %d\n", $1); }
    | '\n'
    ;

expr:
    NUMBER           { $$ = $1; }
    | expr MINUS expr { $$ = $1 - $3; }   /* Conflict resolved by precedence */
    | MINUS expr %prec UMINUS { $$ = -$2; } /* Using %prec to set precedence */
    ;

%%

int main(void) {
    return yyparse();
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}
