%{
#include <stdio.h>

#define YY_DECL int yylex(YYSTYPE *lval, struct parse_params *p)

#include "pslr_fallback_precedence.h"
#include "pslr_fallback_precedence-lexer.h"

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

%token-pattern X /x/
%token-pattern COM /\/\*(.|\n)*\*\//
%token-pattern A /a/
%token-pattern B /ab/
%token-pattern ZA /z/
%token-pattern ZB /z/
%token-pattern PA /@/
%token-pattern PB /@/
%token-pattern NON /non-/
%token-pattern WORD /[a-z-]+/

%lex-prec COM -s COM
%lex-prec WORD -< NON
%lex-prec PA <- PB

%%

start
  : X  { printf("ok\n"); }
  ;

%%

static int
yyerror(YYLTYPE *loc, struct parse_params *p, const char *str)
{
  (void)loc;
  (void)p;
  (void)str;
  return 0;
}

int
main(int argc, char *argv[])
{
  struct parse_params params = { 0 };

  if (argc == 2) {
    yy_scan_string(argv[1]);
  }

  return yyparse(&params);
}
