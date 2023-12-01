%{

#define YYDEBUG 1

#include <stdio.h>
#include "line_number.h"
#include "line_number-lexer.h"

static int yyerror(YYLTYPE *loc, const char *str);
static void line_2(void);

static void
line_1(void)
{
    printf("line_1: %d\n", __LINE__);
}

%}

%union {
    int i;
}

%expect 0

%token <i> NUM

%%

program :   {
              printf("line_pre_program: %d\n", __LINE__);
              line_1();
              line_2();
            }
          expr
            {
              printf("line_post_program: %d\n", __LINE__);
            }
        ;

expr : NUM
     ;

%%

static int
yyerror(YYLTYPE *loc, const char *str) {
    fprintf(stderr, "parse error: %s\\n", str);
    return 0;
}

static void
line_2(void)
{
    printf("line_2: %d\n", __LINE__);
}

int
main(int argc, char *argv[]) {
    yydebug = 1;

    if (argc == 2) {
        yy_scan_string(argv[1]);
    }

    yyparse();
    return 0;
}
