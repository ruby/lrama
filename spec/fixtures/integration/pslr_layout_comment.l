%option noinput nounput noyywrap never-interactive

%{
#include <stdio.h>
#include "pslr_layout_comment.h"

#define YY_DECL int yylex(YYSTYPE *yylval, struct parse_params *p)
%}

%%

(.|\n)+ {
    yypslr_scan_result result;
    int token;

    (void)yylval;
    token = YYPSLR_PSEUDO_SCAN_RESULT(p, yytext, &result);
    if (result.length <= 0) {
        result.length = 1;
    }
    if (result.length < yyleng) {
        yyless(result.length);
    }
    if (result.is_layout) {
        return yylex(yylval, p);
    }
    return token;
}

<<EOF>> {
    return YYEOF;
}

%%
