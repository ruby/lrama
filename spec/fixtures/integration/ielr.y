%{
#include <stdio.h>
#include <stdlib.h>
#include "y.tab.h"
#define YYDEBUG 1
static int yylex(YYSTYPE *val, YYLTYPE *loc);
static int yyerror(YYLTYPE *loc, const char *str);
%}

%union {
    int val;
}

%token a
%token b
%token c
%define lr.type ielr

%%
S: a A B a
 | b A B b
A: a C D E
B: c
 | // empty
C: D
D: a
E: a
 | // empty

%%

static int yylex(YYSTYPE *yylval, YYLTYPE *loc) {
    int c = getchar();
    printf("%c\n", c);
    int val;

    switch (c) {
    case ' ': case '\t':
        return yylex(yylval, loc);

    case 'a': case 'b': case 'c':
        return c;

    case '\n':
        exit(0);

    default:
        fprintf(stderr, "unknown character: %c\n", c);
        exit(1);
    }
}

static int yyerror(YYLTYPE *loc, const char *str) {
    fprintf(stderr, "parse error: %s\n", str);
    return 0;
}

int main() {
    printf("Enter the formula:\n");
    yyparse();
    return 0;
}
