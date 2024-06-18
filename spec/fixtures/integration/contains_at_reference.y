%{

#include <stdio.h>
#include "contains_at_reference.h"
#include "contains_at_reference-lexer.h"

static int yyerror(YYLTYPE *loc, const char *str);

%}

%union {
    int val;
}

%%

program : /* empty */ { (void)@1; }
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
