%{

#define YYDEBUG 1

#include <stdio.h>
#include "printers.h"
#include "printers-lexer.h"

static int yyerror(YYLTYPE *loc, const char *str);

%}

%union {
    int val1;
    int val2;
    int val3;
}

%token <val1> NUM
%type <val2> add
%type <val3> expr
%left '+' '-'
%left '*' '/'

%printer {
    printf("val1: %d\n", $$);
} <val1> // printer for TAG

%printer {
    printf("val2: %d\n", $$);
} <val2>

%printer {
    printf("expr: %d\n", $$);
} expr // printer for symbol

%locations

%%

program : /* empty */
     | expr { printf("=> %d", $1); }
     ;

add  : expr '+' expr { $$ = $1 + $3; }

expr : NUM
     | add
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
    yydebug = 1;

    if (argc == 2) {
        yy_scan_string(argv[1]);
    }

    if (yyparse()) {
        fprintf(stderr, "syntax error\n");
        return 1;
    }
    return 0;
}
