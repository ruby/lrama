%{

#define YYDEBUG 1

#include <stdio.h>
#include <stdint.h>

#include "user_defined_parameterized.h"
#include "user_defined_parameterized-lexer.h"

static int yyerror(YYLTYPE *loc, const char *str);

%}

%expect 0

%union {
    int num;
    void* ptr;
    lrama_list_node_t* list;
}

%token <num> ODD EVEN

%type <num> stmt
%type <ptr> stmt_wrapped
%type <list> stmts

%rule pair(X, Y): X Y
                    {
                        $$ = $1 + $2;
                        printf("(%d, %d)\n", $1, $2);
                        printf("(%d, %d)\n", $X, $2);
                        printf("(%d, %d)\n", $:1, $:2);
                    }
                ;

%locations

%%

program: stmts { lrama_list_free($1);}
       ;

stmts: separated_list(';', stmt_wrapped) <list> { $$ = $1; }
     ;

stmt_wrapped: stmt { $$ = (void*)(intptr_t)$1; }
            ;

stmt: pair(ODD, EVEN) <num> { printf("pair odd even: %d\n", $1); $$ = $1; }
    | pair(EVEN, ODD)[result] <num> { printf("pair even odd: %d\n", $result); $$ = $result; }
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
