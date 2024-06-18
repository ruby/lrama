%{
#define YYDEBUG 1
#include <stdio.h>

#define YY_LOCATION_PRINT(File, loc, p) ((void) 0)

#define YY_DECL yylex (YYSTYPE *lval, YYLTYPE *yylloc, int parser_params)

#include "params.h"
#include "params-lexer.h"

extern int yylex(YYSTYPE *lval, YYLTYPE *yylloc, int parser_params);
static int yyerror(YYLTYPE *loc, int parse_param, const char *str);

%}

%lex-param {int parse_param}
%parse-param {int parse_param}

%union {
    int val;
}

%token <val> NUM
%type <val> expr
%left '+' '-'
%left '*' '/'

%locations

%%

program : /* empty */
     | expr { printf("=> %d", $1); }
     ;
expr : NUM
     | expr '+' expr { $$ = $1 + $3; }
     | expr '-' expr { $$ = $1 - $3; }
     | expr '*' expr { $$ = $1 * $3; }
     | expr '/' expr { $$ = $1 / $3; }
     | '(' expr ')'  { $$ = $2; }
     ;

%%

static int yyerror(YYLTYPE *loc, int parse_param, const char *str) {
    fprintf(stderr, "parse error: %s\\n", str);
    return 0;
}

int main(int argc, char *argv[]) {
    if (argc == 2) {
        yy_scan_string(argv[1]);
    }

    if (yyparse(0)) {
        fprintf(stderr, "syntax error\n");
        return 1;
    }
    return 0;
}
