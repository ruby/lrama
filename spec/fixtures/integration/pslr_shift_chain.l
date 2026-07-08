%option noinput nounput noyywrap never-interactive

%{
#include <stdio.h>
#include "pslr_shift_chain.h"

#define YY_DECL int yylex(YYSTYPE *yylval, struct parse_params *p)
%}

ID_PATTERN [a-z]+

%%

{ID_PATTERN} {
    (void)yylval;
    return ID;
}

"<" {
    return LT;
}

"@" {
    return START;
}

"#" {
    return MARK;
}

[>]{1,2} {
    int match_length = 0;
    int token = YYPSLR_PSEUDO_SCAN(p, yytext, &match_length);

    if (token == YYEMPTY) {
        token = (yyleng == 2) ? RSHIFT : RANGLE;
        match_length = yyleng;
    }

    if (0 < match_length && match_length < yyleng) {
        yyless(match_length);
    }

    return token;
}

[[:space:]]+ {}

<<EOF>> {
    return YYEOF;
}

. {
    fprintf(stderr, "Illegal character '%s'\n", yytext);
    return YYUNDEF;
}

%%
