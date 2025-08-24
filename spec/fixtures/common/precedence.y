%{
#include <stdio.h>
#include <stdlib.h>

int yylex(void);
void yyerror(const char *s);
%}

%union {
    int i;
    void* p;
}

%left <i> PLUS MINUS <p> ADD_OP
%left <i> MULT DIV MOD <p> MULT_OP
%left DIV_OP P_MULT_OP <p> P_DIV_OP

%token <i> NUMBER
%token <i> LPAREN RPAREN

%type <i> expr term factor

%%

program:
    expr { printf("Result: %d\n", $1); }
    ;

expr:
    expr PLUS term          { $$ = $1 + $3; }
    | expr MINUS term       { $$ = $1 - $3; }
    | expr ADD_OP term      { $$ = $1 + $3; }
    | term                  { $$ = $1; }
    ;

term:
    term MULT factor        { $$ = $1 * $3; }
    | term DIV factor       { $$ = $1 / $3; }
    | term MOD factor       { $$ = $1 % $3; }
    | term MULT_OP factor   { $$ = $1 * $3; }
    | factor                { $$ = $1; }
    ;

factor:
    NUMBER                  { $$ = $1; }
    | LPAREN expr RPAREN    { $$ = $2; }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main(void) {
    return yyparse();
}
