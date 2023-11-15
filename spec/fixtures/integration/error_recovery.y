%{

#include <stdio.h>
#include "error_recovery.h"
#include "error_recovery-lexer.h"

static int yyerror(YYLTYPE *loc, const char *str);

%}

%union {
    int val;
}

%token <val> NUM
%type <val> expr
%left '+' '-'
%left '*' '/'

%error-token {
    $$ = 100;
} NUM

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

    yyparse();
    return 0;
}
