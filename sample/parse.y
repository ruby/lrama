/*
 * This is comment for this file.
 */

%{
// Prologue

#include "y.tab.h"

static enum yytokentype yylex(YYSTYPE *lval, YYLTYPE *yylloc);
static void yyerror(YYLTYPE *yylloc, const char *msg);

%}

%expect 0
%define api.pure
%define parse.error verbose

%union {
    int i;
}

%token <i> number

%%

program         : expr
                ;

expr            : term '+' expr
                | term
                ;

term            : factor '*' term
                | factor
                ;

factor          : number
                ;

%%

// Epilogue

static enum yytokentype
yylex(YYSTYPE *lval, YYLTYPE *yylloc)
{
    return 0;
}

static void yyerror(YYLTYPE *yylloc, const char *msg)
{
    (void) msg;
}

int main(int argc, char *argv[])
{
}
