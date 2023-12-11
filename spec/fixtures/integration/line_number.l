%option noinput nounput noyywrap never-interactive yylineno bison-bridge bison-locations

%{

#include <stdio.h>
#include <stdlib.h>
#include "line_number.h"

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
    yylval->i = atoi(yytext);
    return NUM;
}

[+\-\*\/\(\)] {
    return yytext[0];
}

[\n|\r\n] {}

[[:space:]] {}

<<EOF>> {
    return(YYEOF);
}

. {
    fprintf(stderr, "Illegal character '%s'\n", yytext);
    return(YYEOF);
}

%%