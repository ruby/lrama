%{
#include <stdio.h>
#include <stdlib.h>

int yylex(void);
void yyerror(const char *s);
%}

%union {
    int ival;
    void *pval;
}

%left <ival> PLUS MINUS <pval> PLUGIN_ADD_OP
%left <ival> MULT DIV MOD <pval> PLUGIN_MULT_OP
%right <ival> POW <pval> PLUGIN_POW_OP
%left <ival> OROR DORDOR <pval> PLUGIN_LOGICAL_OR_OP
%left <ival> ANDAND <pval> PLUGIN_LOGICAL_AND_OP

%token <ival> NUMBER
%token <ival> LPAREN RPAREN
%token ID STRING

%type <ival> expr term factor

%%

program:
    expr { printf("Result: %d\n", $1); }
    ;

expr:
    expr PLUS term          { $$ = $1 + $3; }
    | expr MINUS term       { $$ = $1 - $3; }
    | expr PLUGIN_ADD_OP term { $$ = $1 + $3; }
    | expr OROR term        { $$ = $1 || $3; }
    | expr DORDOR term      { $$ = $1 || $3; }
    | expr PLUGIN_LOGICAL_OR_OP term { $$ = $1 || $3; }
    | expr ANDAND term      { $$ = $1 && $3; }
    | expr PLUGIN_LOGICAL_AND_OP term { $$ = $1 && $3; }
    | term                  { $$ = $1; }
    ;

term:
    term MULT factor        { $$ = $1 * $3; }
    | term DIV factor       { $$ = $1 / $3; }
    | term MOD factor       { $$ = $1 % $3; }
    | term PLUGIN_MULT_OP factor { $$ = $1 * $3; }
    | factor                { $$ = $1; }
    ;

factor:
    NUMBER                  { $$ = $1; }
    | LPAREN expr RPAREN    { $$ = $2; }
    | factor POW factor     { $$ = pow($1, $3); }
    | factor PLUGIN_POW_OP factor { $$ = pow($1, $3); }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main(void) {
    return yyparse();
}
