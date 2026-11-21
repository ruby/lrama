/*
 * %inline Use Case: This file demonstrates the PROBLEM.
 *
 * "expr op expr" has undefined precedence because 'op' is a nonterminal.
 * Even though %left PLUS and %left TIMES are declared, they are NOT used.
 *
 *   $ lrama -W calc_no_inline.y
 *   => shift/reduce conflicts: 2 found
 *   => Precedence PLUS is defined but not used in any rule.
 *   => Precedence TIMES is defined but not used in any rule.
 *
 * See calc_inline.y for the solution using %inline.
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
 * PROBLEM: "expr op expr" has undefined precedence.
 * The rightmost terminal of this rule is... what?
 * 'op' is nonterminal, so no precedence is inherited.
 */
expr: NUM
    | expr op expr { $$ = $<val>2 ? $1 * $3 : $1 + $3; }
    | '(' expr ')' { $$ = $2; }
    ;

/*
 * 'op' is a regular nonterminal - not inlined.
 * This causes the precedence problem above.
 */
op: PLUS  { $<val>$ = 0; }
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
    printf("Test: 1+2*3 should be 7, but may be wrong due to conflicts\n");
    return yyparse();
}
