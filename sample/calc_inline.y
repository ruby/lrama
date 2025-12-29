/*
 * %inline Use Case: Resolving Precedence Conflicts
 *
 * PROBLEM (see calc_no_inline.y):
 *   "expr op expr" has undefined precedence because 'op' is a nonterminal.
 *   Result: shift/reduce conflicts, and %left PLUS/%left TIMES are unused.
 *
 *   $ lrama -W calc_no_inline.y
 *   => shift/reduce conflicts: 2 found
 *   => Precedence PLUS is defined but not used in any rule.
 *   => Precedence TIMES is defined but not used in any rule.
 *
 * SOLUTION (this file):
 *   With %inline, 'op' is expanded inline, producing:
 *     expr PLUS expr   <- PLUS precedence applies
 *     expr TIMES expr  <- TIMES precedence applies
 *
 *   $ lrama -W calc_inline.y
 *   => no conflicts
 *
 * Build:
 *   $ lrama -d calc_inline.y -o calc_inline.c && gcc calc_inline.c -o calc_inline
 */

%{
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
%}

%code provides {
static int yylex(YYSTYPE *val, YYLTYPE *loc);
static int yyerror(YYLTYPE *loc, const char *str);
}

%union {
    int val;
}

%token <val> NUM
%token PLUS TIMES
%token LF

%type <val> expr

%left PLUS
%left TIMES

%locations

%%

program: /* empty */
       | program expr LF { printf("=> %d\n", $2); }
       | program LF
       ;

/*
 * KEY POINT:
 *
 * "expr op expr" has undefined precedence because 'op' is nonterminal.
 *
 * With %inline, this expands to:
 *   expr PLUS expr   <- inherits PLUS precedence
 *   expr TIMES expr  <- inherits TIMES precedence
 */
expr: NUM
    | expr op expr { $$ = $<val>2 ? $1 * $3 : $1 + $3; }
    | '(' expr ')' { $$ = $2; }
    ;

/*
 * Remove "%inline" here to see the conflict.
 */
%rule %inline op: PLUS  { $<val>$ = 0; }
                | TIMES { $<val>$ = 1; }
                ;

%%

static int yylex(YYSTYPE *yylval, YYLTYPE *loc) {
    int c;
    while ((c = getchar()) == ' ' || c == '\t');
    if (isdigit(c)) {
        int val = c - '0';
        while (isdigit(c = getchar())) val = val * 10 + (c - '0');
        ungetc(c, stdin);
        yylval->val = val;
        return NUM;
    }
    if (c == '+') return PLUS;
    if (c == '*') return TIMES;
    if (c == '\n') return LF;
    if (c == '(' || c == ')') return c;
    if (c == EOF) exit(0);
    return c;
}

static int yyerror(YYLTYPE *loc, const char *s) {
    fprintf(stderr, "%s\n", s);
    return 0;
}

int main(void) {
    printf("Test: 1+2*3 should be 7, (1+2)*3 should be 9\n");
    return yyparse();
}
