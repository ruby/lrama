%option noinput nounput noyywrap never-interactive yylineno bison-bridge bison-locations

%{

#include <stdio.h>
#include <stdlib.h>
#include "parser_state.h"

int yycolumn = 0;

#define YY_USER_ACTION \
    yylloc->first_line = yylloc->last_line = yylineno; \
    yylloc->first_column = yycolumn; \
    yylloc->last_column = yycolumn + yyleng; \
    yycolumn += yyleng; \

%}

NUMBER [0-9]+

%%

{NUMBER} {
    yylval->i = atoi(yytext);
    return NUM;
}

[+\-\*\/\(\)] {
    return yytext[0];
}

[\n|\r\n] {}

[[:space:]] {}

"begin" {
    return keyword_begin;
}

"end" {
    return keyword_end;
}

"rescue" {
    return keyword_rescue;
}

"else" {
    return keyword_else;
}

"ensure" {
    return keyword_ensure;
}

"class" {
    return keyword_class;
}

"def" {
    return keyword_def;
}

[A-Z]+ {
    yylval->str = strdup(yytext);
    fprintf(stderr, "%s\n", yytext);
    return cname;
}

[a-z][a-z0-9]+ {
    yylval->str = strdup(yytext);
    fprintf(stderr, "%s\n", yytext);
	return fname;
}

<<EOF>> {
    return(YYEOF);
}

. {
    fprintf(stderr, "Illegal character '%s'\n", yytext);
    return(YYEOF);
}

%%
