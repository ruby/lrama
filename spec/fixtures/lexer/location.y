/*
 * This is a valid　sample grammar file.
 * It works as simple calculator.
 */

%{
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

#include "calc.h"

static int yylex(YYSTYPE *val, YYLTYPE *loc);
static int yyerror(YYLTYPE *loc, const char *str);
%}

%union {
    int val;
}
%token LF
%token <val> NUM
%type <val> expr
%left '+' '-'
%left '*' '/'

%%

list : /* empty */
     | list LF
     | list expr LF { printf("=> %d\n", $2); }
     ;
expr : NUM
     | expr '+' expr { $$ = $1 + $3; }
     | expr '-' expr { $$ = $1 - $3; }
     | expr '*' expr { $$ = $1 * $3; }
     | expr '/' expr { $$ = $1 / $3; }
     | '(' expr ')'
         {
           printf("debug %d\n", $1);
           $$ = $2;
           printf("debug %d\n", $3);
         }
     ;

%%

static int yylex(YYSTYPE *yylval, YYLTYPE *loc) {
    int c = getchar();
    int val;

    switch (c) {
    case ' ': case '\t':
        return yylex(yylval, loc);

    case '0': case '1': case '2': case '3': case '4':
    case '5': case '6': case '7': case '8': case '9':
        val = c - '0';
        while (1) {
            c = getchar();
            if (isdigit(c)) {
                val = val * 10 + (c - '0');
            }
            else {
                ungetc(c, stdin);
                break;
            }
        }
        yylval->val = val;
        return NUM;

    case '\n':
        return LF;

    case '+': case '-': case '*': case '/': case '(': case ')':
        return c;

    case EOF:
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
