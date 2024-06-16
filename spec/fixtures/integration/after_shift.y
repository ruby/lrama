%{

#include <stdio.h>
#include "after_shift.h"
#include "after_shift-lexer.h"

static int yyerror(YYLTYPE *loc, const char *str);

static void
after_shift(void)
{
    printf("after-shift: %d\n", __LINE__);
}

static void
before_reduce(int len)
{
    printf("before-reduce: %d, %d\n", __LINE__, len);
}

static void
after_reduce(int len)
{
    printf("after-reduce: %d, %d\n", __LINE__, len);
}

static void
after_shift_error_token(void)
{
    printf("after-shift-error-token: %d\n", __LINE__);
}

static void
after_pop_stack(int len)
{
    printf("after-pop-stack: %d, %d\n", __LINE__, len);
}

%}

%union {
    int val;
}

%after-shift after_shift
%before-reduce before_reduce
%after-reduce after_reduce
%after-shift-error-token after_shift_error_token
%after-pop-stack after_pop_stack

%token <val> NUM
%type <val> expr
%left '+' '-'
%left '*' '/'

%locations

%%

program : /* empty */
     | expr { printf("=> %d\n", $1); }
     | error
         {
           printf("error (%d)\n", $:1);
         }
     ;

expr : NUM
     | expr '+' expr
         {
           $$ = $1 + $3;
           printf("+ (%d, %d, %d)\n", $:1, $:2, $:3);
         }
     | expr '-' expr
         {
           $$ = $1 - $3;
           printf("- (%d, %d, %d)\n", $:1, $:2, $:3);
         }
     | expr '*' expr
         {
           $$ = $1 * $3;
           printf("* (%d, %d, %d)\n", $:1, $:2, $:3);
         }
     | expr '/' expr
         {
           $$ = $1 / $3;
           printf("/ (%d, %d, %d)\n", $:1, $:2, $:3);
         }
     | '(' expr ')'
         {
           $$ = $2;
           printf("(...) (%d, %d, %d)\n", $:1, $:2, $:3);
         }
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
