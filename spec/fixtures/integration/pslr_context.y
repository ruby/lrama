%{
#include <stdio.h>

#include "pslr_context.h"
#include "pslr_context-lexer.h"

extern int yylex(YYSTYPE *lval, struct parse_params *p);
static int yyerror(YYLTYPE *loc, struct parse_params *p, const char *str);
%}

%code requires {
  struct parse_params {
    int current_state;
  };
}

%define api.pure
%define lr.type pslr
%define api.pslr.state-member current_state

%lex-param {struct parse_params *p}
%parse-param {struct parse_params *p}

%token-pattern RSHIFT />>/
%token-pattern RANGLE />/
%token-pattern LANGLE /</
%token-pattern ID /[a-zA-Z_][a-zA-Z0-9_]*/

%lex-prec RANGLE -s RSHIFT

%%

program
  : template_expr { printf("template\n"); }
  | shift_expr { printf("shift\n"); }
  ;

template_expr
  : ID LANGLE ID RANGLE
  | ID LANGLE ID LANGLE ID RANGLE RANGLE
  ;

shift_expr
  : ID RSHIFT ID
  ;

%%

static int
yyerror(YYLTYPE *loc, struct parse_params *p, const char *str)
{
  (void)loc;
  (void)p;
  fprintf(stderr, "parse error: %s\n", str);
  return 0;
}

int
main(int argc, char *argv[])
{
  struct parse_params params = { 0 };

  if (argc == 2) {
    yy_scan_string(argv[1]);
  }

  if (yyparse(&params)) {
    fprintf(stderr, "syntax error\n");
    return 1;
  }

  return 0;
}
