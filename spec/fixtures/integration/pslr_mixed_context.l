%option noinput nounput noyywrap never-interactive

%{
#include <stdio.h>
#include "pslr_mixed_context.h"

#define YY_DECL int yylex(YYSTYPE *yylval, struct parse_params *p)
%}

%%

[a-z]+ {
    (void)yylval;

    int match_length = 0;
    int token = yy_pseudo_scan(p->current_state, yytext, &match_length);

    if (token == YYEMPTY) {
        token = ID;
        match_length = yyleng;
    }

    if (0 < match_length && match_length < yyleng) {
        yyless(match_length);
    }

    return token;
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
    int token = yy_pseudo_scan(p->current_state, yytext, &match_length);

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
