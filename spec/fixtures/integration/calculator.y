%{

#include <stdio.h>
#include "calculator.h"
#include "calculator-lexer.h"

static int yyerror(YYLTYPE *loc, const char *str);

%}

%union {
    int val;
}

%token <val> NUM
%type <val> expr
%left '+' '-'
%left '*' '/'

%%

program : /* empty */
     | expr { printf("=> %d", $1); }
     ;
expr : NUM
     | expr '+' expr { $$ = $1 + $3; }
     | expr '-' expr { $$ = $1 - $3; }
     | expr '*' expr { $$ = $1 * $3; }
     | expr '/' expr { $$ = $1 / $3; }
     | '(' expr ')'  { $$ = $2; }
     ;

%%

static int yyerror(YYLTYPE *loc, const char *str) {
    fprintf(stderr, "parse error: %s\n", str);
    return 0;
}

int main(int argc, char *argv[]) {
    if (argc == 2) {
        yy_scan_string(argv[1]);
    }

    if (yyparse()) {
        fprintf(stderr, "syntax error\n");
        return 1;
    }
    return 0;
}
