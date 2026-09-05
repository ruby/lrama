%{
#include <stdio.h>

#define YY_DECL int yylex(YYSTYPE *lval, struct parse_params *p)

#include "pslr_layout_comment.h"
#include "pslr_layout_comment-lexer.h"

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

%token ID
%token DIV "/"
%token SEMI ";"

%token-pattern ID /[a-zA-Z][a-zA-Z0-9_]*/
%token-pattern DIV /\//
%token-pattern SEMI /;/
%token-pattern YYLAYOUT_COMMENT /\/\*([^*]|\*+[^*/])*\*+\//
%token-pattern YYLAYOUT_WS /[ \t\r\n]+/

%lex-prec DIV -~ YYLAYOUT_COMMENT

%%

start
  : ID DIV ID SEMI  { printf("ok\n"); }
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
