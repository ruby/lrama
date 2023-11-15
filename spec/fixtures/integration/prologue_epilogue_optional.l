%option noinput nounput noyywrap never-interactive yylineno bison-bridge bison-locations

%{

#include <stdio.h>
#include <stdlib.h>
#include "prologue_epilogue_optional.h"

%}

NUMBER [0-9]+

%%

{NUMBER} {
    ((void) yylloc);
    yylval->val = atoi(yytext);
    return 1;
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
