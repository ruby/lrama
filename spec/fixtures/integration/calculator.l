%option noinput nounput noyywrap never-interactive bison-bridge bison-locations

%{

#include <stdio.h>
#include <stdlib.h>
#include "calculator.h"

%}

NUMBER [0-9]+

%%

{NUMBER} {
    ((void) yylloc);
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
