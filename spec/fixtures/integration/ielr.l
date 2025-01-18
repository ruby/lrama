%option noinput nounput noyywrap never-interactive bison-bridge bison-locations

%{

#include <stdio.h>
#include <stdlib.h>
#include "bison-generated.h"
#include "bison-generated-lexer.h"

%}

%%


[abc] {
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
