%option noinput nounput noyywrap never-interactive yylineno bison-bridge bison-locations

%{

#include <stdio.h>
#include <stdlib.h>
#include "user_defined_parameterized.h"

int yycolumn = 0;

#define YY_USER_ACTION \
    yylloc->first_line = yylloc->last_line = yylineno; \
    yylloc->first_column = yycolumn; \
    yylloc->last_column = yycolumn + yyleng; \
    yycolumn += yyleng; \

%}

ODD  [13579]
EVEN [02468]

%%

{ODD} {
    yylval->num = atoi(yytext);
    return ODD;
}

{EVEN} {
    yylval->num = atoi(yytext);
    return EVEN;
}

[;] {
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
