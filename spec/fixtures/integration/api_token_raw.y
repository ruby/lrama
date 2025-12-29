%{

#include <stdio.h>
#include "api_token_raw.h"
#include "api_token_raw-lexer.h"

static int yyerror(YYLTYPE *loc, const char *str);

%}

%define api.token.raw

%union {
    int val;
}

%token <val> NUM
%token PLUS MINUS STAR SLASH LPAREN RPAREN
%type <val> expr
%left PLUS MINUS
%left STAR SLASH

%locations

%%

program : /* empty */
     | expr { printf("=> %d", $1); }
     ;
expr : NUM
     | expr PLUS expr { $$ = $1 + $3; }
     | expr MINUS expr { $$ = $1 - $3; }
     | expr STAR expr { $$ = $1 * $3; }
     | expr SLASH expr { $$ = $1 / $3; }
     | LPAREN expr RPAREN  { $$ = $2; }
     ;

%%

static int yyerror(YYLTYPE *loc, const char *str) {
    fprintf(stderr, "parse error: %s\n", str);
    return 0;
}

int main(int argc, char *argv[]) {
    if (argc == 2) {
        yy_scan_string(argv[1]);
    }

    if (yyparse()) {
        fprintf(stderr, "syntax error\n");
        return 1;
    }
    return 0;
}
