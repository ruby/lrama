%{
#include <stdio.h>

typedef struct code_location {
  int first_line;
  int first_column;
  int last_line;
  int last_column;
#ifdef __cplusplus
  code_location()
    : first_line(0), first_column(0), last_line(0), last_column(0) {}
#endif
} code_location_t;

#define YYLTYPE code_location_t
#define YYLLOC_DEFAULT(Current, Rhs, N)                           \
  do                                                              \
    if (N)                                                        \
      {                                                           \
        (Current).first_line = YYRHSLOC(Rhs, 1).first_line;       \
        (Current).first_column = YYRHSLOC(Rhs, 1).first_column;   \
        (Current).last_line = YYRHSLOC(Rhs, N).last_line;         \
        (Current).last_column = YYRHSLOC(Rhs, N).last_column;     \
      }                                                           \
    else                                                          \
      {                                                           \
        (Current).first_line = YYRHSLOC(Rhs, 0).last_line;        \
        (Current).first_column = YYRHSLOC(Rhs, 0).last_column;    \
        (Current).last_line = YYRHSLOC(Rhs, 0).last_line;         \
        (Current).last_column = YYRHSLOC(Rhs, 0).last_column;     \
      }                                                           \
  while (0)

#include "named_references.h"
#include "named_references-lexer.h"

static void print_location(YYLTYPE *loc);
static int yyerror(YYLTYPE *loc, const char *str);

%}

%union {
    int val;
}
%token <val> NUM
%type <val> expr

%locations

%%

line: expr
        {
          printf("line (%d): ", @expr.first_line);
          print_location(&@expr);

          printf("=> %d", $expr);
        }
    ;

expr[result]: NUM
            | expr[ex-left] expr[ex.right] '+'
                {
                  printf("expr[ex-left] (%d): ", @[ex-left].first_line);
                  print_location(&@[ex-left]);

                  printf("expr[ex.right] (%d): ", @[ex.right].first_line);
                  print_location(&@[ex.right]);

                  $result = $[ex-left] + $[ex.right];
                }
            ;

%%

static void print_location(YYLTYPE *loc) {
  printf("%d.%d-%d.%d. ", loc->first_line, loc->first_column, loc->last_line, loc->last_column);
}

static int yyerror(YYLTYPE *loc, const char *str) {
    fprintf(stderr, "parse error: %s\\n", str);
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
