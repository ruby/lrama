%{

#define YYDEBUG 1

#include <stdio.h>
#include "attributes.h"
#include "attributes-lexer.h"

static int yyerror(YYLTYPE *loc, const char *str);

%}

%union {
    int i;
    char *str;
}

%expect 0

%token <i> NUM

%type <i> expr expr_brace expr2

/*
 *  precedence table
 */

%left '+'
%left '*'

%%

program : expr       { printf("=> %d", $1); }
        | expr_brace { printf("=> %d", $1); }
        ;

expr : NUM
     | expr '+' expr { $$ = $1 + $3; }
     | expr '*' expr { $$ = $1 * $3; }
     ;

expr_brace : '{' expr2 '}' { $$ = $2; }
           ;

expr2 : NUM
      | [@prec '+' '*'] [@prec '*' '+'] expr2 '+' expr2 { $$ = $1 + $3; }
      | [@prec '+' '*'] [@prec '*' '+'] expr2 '*' expr2 { $$ = $1 * $3; }
      ;

%%

static int yyerror(YYLTYPE *loc, const char *str) {
    fprintf(stderr, "parse error: %s\\n", str);
    return 0;
}

int main(int argc, char *argv[]) {
    yydebug = 1;

    if (argc == 2) {
        yy_scan_string(argv[1]);
    }

    yyparse();
    return 0;
}
