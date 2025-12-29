%option noinput nounput noyywrap never-interactive bison-bridge bison-locations

%{

#include <stdio.h>
#include <stdlib.h>
#include "api_token_raw.h"

%}

NUMBER [0-9]+

%%

{NUMBER} {
    ((void) yylloc);
    yylval->val = atoi(yytext);
    return NUM;
}

"+" {
    return PLUS;
}

"-" {
    return MINUS;
}

"*" {
    return STAR;
}

"/" {
    return SLASH;
}

"(" {
    return LPAREN;
}

")" {
    return RPAREN;
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
