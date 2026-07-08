%{
#include <stdio.h>
#include <string.h>

#define YY_DECL int yylex(YYSTYPE *lval, struct parse_params *p)

#include "pslr_implicit_literal.h"
#include "pslr_implicit_literal-lexer.h"

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

%token-pattern ID /[a-z]+/

%%

start
  : ID ';'  { printf("ok\n"); }
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

  if (argc == 2 && strcmp(argv[1], "__fallback_semi__") == 0) {
    yypslr_scan_result result;
    int token = YYPSLR_PSEUDO_SCAN_RESULT(&params, ";", &result);
    int ok = token == ';' && result.token == ';' && result.length == 1 &&
      result.is_character_token == 0;

    printf("%s %d %d\n", ok ? "SEMI" : "BAD", result.length, result.is_character_token);
    return ok ? 0 : 1;
  }

  if (argc == 2) {
    yy_scan_string(argv[1]);
  }

  return yyparse(&params);
}
