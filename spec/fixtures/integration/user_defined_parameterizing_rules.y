%{

#define YYDEBUG 1

#include <stdio.h>

#include "user_defined_parameterizing_rules.h"
#include "user_defined_parameterizing_rules-lexer.h"

static int yyerror(YYLTYPE *loc, const char *str);

%}

%expect 0

%union {
    int num;
}

%token <num> ODD EVEN

%rule pair(X, Y): X Y { printf("(%d, %d)\n", $1, $2); }
                ;

%%

program: stmts
       ;

stmts: separated_list(';', stmt)
     ;

stmt: pair(ODD, EVEN) { printf("pair odd even\n"); }
    | pair(EVEN, ODD) { printf("pair even odd\n"); }
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
