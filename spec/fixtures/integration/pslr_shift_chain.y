%{
#include <stdio.h>

#define YYSETSTATE_CONTEXT(CurrentState, ParseParam) ((ParseParam)->current_state = (CurrentState))

#include "pslr_shift_chain.h"
#include "pslr_shift_chain-lexer.h"

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

%lex-param {struct parse_params *p}
%parse-param {struct parse_params *p}

%token-pattern LT /</
%token-pattern START /@/
%token-pattern MARK /#/
%token-pattern RSHIFT />>/
%token-pattern RANGLE />/
%token-pattern ID /[a-z]+/

%lex-prec RANGLE -s RSHIFT

%%

program
  : template_expr { printf("template\n"); }
  | shift_expr { printf("shift\n"); }
  ;

template_expr
  : LT shared RANGLE
  ;

shift_expr
  : START shared RSHIFT ID
  ;

shared
  : n1
  ;

n1
  : n2
  ;

n2
  : MARK
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
