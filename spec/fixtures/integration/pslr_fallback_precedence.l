%option noinput nounput noyywrap never-interactive

%{
#include <stdio.h>
#include "pslr_fallback_precedence.h"

#define YY_DECL int yylex(YYSTYPE *yylval, struct parse_params *p)

static const char *
token_name(int token)
{
    switch (token) {
    case X:
        return "X";
    case COM:
        return "COM";
    case A:
        return "A";
    case B:
        return "B";
    case SHORT:
        return "SHORT";
    case IA:
        return "IA";
    case IB:
        return "IB";
    case CYC_A:
        return "CYC_A";
    case CYC_B:
        return "CYC_B";
    case CYC_C:
        return "CYC_C";
    case ZA:
        return "ZA";
    case ZB:
        return "ZB";
    case PA:
        return "PA";
    case PB:
        return "PB";
    case NON:
        return "NON";
    case WORD:
        return "WORD";
    default:
        return "UNKNOWN";
    }
}
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
    printf("%s %d\n", token_name(token), result.length);
    if (result.length < yyleng) {
        yyless(result.length);
    }
    return token;
}

<<EOF>> {
    return YYEOF;
}

%%
