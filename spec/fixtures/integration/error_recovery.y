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
%token <val> LPAREN "("
%token <val> RPAREN ")"
%type <val> stmt
%type <val> expr
%left '+' '-'
%left '*' '/'

%locations

%error-token {
    $$ = 100;
} NUM RPAREN

%%

program : /* empty */
     | stmt { printf("=> %d", $1); }
     ;
stmt : expr { $$ = $1; }
     | LPAREN expr RPAREN
        {
            if ($3 == 100) {
                $$ = $2 + $3;
            } else {
                $$ = $2;
            }
        }
     ;
expr : NUM
     | expr '+' expr { $$ = $1 + $3; }
     | expr '-' expr { $$ = $1 - $3; }
     | expr '*' expr { $$ = $1 * $3; }
     | expr '/' expr { $$ = $1 / $3; }
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
