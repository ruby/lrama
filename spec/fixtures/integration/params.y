%{
#define YYDEBUG 1
#include <stdio.h>

#define YY_LOCATION_PRINT(File, loc, ...) ((void) 0)

#define YY_DECL yylex (YYSTYPE *lval, YYLTYPE *yylloc, int lexer_value, int shared, int offset, int *errors)

#include "params.h"
#include "params-lexer.h"

static int lexer_value = 7;
extern int yylex(YYSTYPE *lval, YYLTYPE *yylloc, int lexer_value, int shared, int offset, int *errors);
static int yyerror(YYLTYPE *loc, int parser_value, int shared, int offset, int *errors, const char *str);

%}

%lex-param {int lexer_value}
%parse-param {int parser_value}
%param {int shared} {int offset}
%param {int *errors}

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
     | expr {
         if (parser_value != 3 || shared != 5 || offset != 11 || *errors)
             YYABORT;
         printf("=> %d", $1);
       }
     ;
expr : NUM
     | expr '+' expr { $$ = $1 + $3; }
     | expr '-' expr { $$ = $1 - $3; }
     | expr '*' expr { $$ = $1 * $3; }
     | expr '/' expr { $$ = $1 / $3; }
     | '(' expr ')'  { $$ = $2; }
     ;

%%

static int yyerror(YYLTYPE *loc, int parser_value, int shared, int offset, int *errors, const char *str) {
    if (parser_value == 3 && shared == 5 && offset == 11)
        ++*errors;
    fprintf(stderr, "parse error: %s\\n", str);
    return 0;
}

int main(int argc, char *argv[]) {
    int errors = 0;
    if (argc == 2) {
        yy_scan_string(argv[1]);
    }

    if (yyparse(3, 5, 11, &errors)) {
        printf("errors: %d", errors);
        fprintf(stderr, "syntax error\n");
        return 1;
    }
    return errors != 0;
}
