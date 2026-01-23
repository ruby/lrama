%option noinput nounput noyywrap never-interactive bison-bridge bison-locations

%{

#include <stdio.h>
#include <stdlib.h>
#include "no_union.h"

%}

NUMBER [0-9]+

%%

{NUMBER} {
    ((void) yylloc);
    *yylval = atoi(yytext);
    return NUMBER;
}

[+\-] {
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
