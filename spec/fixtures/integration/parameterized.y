%{

#define YYDEBUG 1

#include <stdio.h>

#include "parameterized.h"
#include "parameterized-lexer.h"

static int yyerror(YYLTYPE *loc, const char *str);

%}

%expect 0

%union {
    int num;
    char* str;
}

%token <num> ODD EVEN

%type <num> stmt
%type <str> opt_nl

%locations

%%

program: stmts
       ;

stmts: stmt+
     ;

stmt: ODD opt_nl { printf("odd: %d\n", $1); }
    | EVEN opt_semicolon { printf("even: %d\n", $1); }
    ;

opt_nl: '\n'?[nl] <str> { $$ = $nl; }
      ;

opt_semicolon: semicolon?
             ;

semicolon: ';'
         ;

%%

static int yyerror(YYLTYPE *loc, const char *str) {
    fprintf(stderr, "parse error: %s\\n", str);
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
