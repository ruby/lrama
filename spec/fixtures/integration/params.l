%option noinput nounput noyywrap never-interactive yylineno

%{

#include <stdio.h>
#include <stdlib.h>
#include "params.h"

#define YY_DECL int yylex (YYSTYPE *yylval, YYLTYPE *yylloc, int parser_params)

int yycolumn = 0;

#define YY_USER_ACTION \
    yylloc->first_line = yylloc->last_line = yylineno; \
    yylloc->first_column = yycolumn; \
    yylloc->last_column = yycolumn + yyleng; \
    yycolumn += yyleng; \

%}

NUMBER [0-9]+

%%

{NUMBER} {
    yylval->val = atoi(yytext);
    return NUM;
}

[+\-\*\/\(\)] {
    return yytext[0];
}

[\n|\r\n] {
    return(YYEOF);
}

[[:space:]] {}

<<EOF>> {
    return(YYEOF);
}

. {
    fprintf(stderr, "Illegal character '%s'\n", yytext);
    return(YYEOF);
}

%%
