%{
#include <stdio.h>
#include <string.h>

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
%token-pattern SHORT /c/
%token-pattern IA /cd/
%token-pattern IB /cd/
%token-pattern ZA /z/
%token-pattern ZB /z/
%token-pattern PA /@/
%token-pattern PB /@/
%token-pattern NON /non-/
%token-pattern WORD /[a-z-]+/

%lex-prec COM -s COM
%lex-prec WORD -< NON
%lex-prec PA <- PB
%lex-prec IA <- IB

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

  if (argc == 2 && strcmp(argv[1], "__empty__") == 0) {
    yypslr_scan_result result;
    int match_length = -1;
    int token = YYPSLR_PSEUDO_SCAN_RESULT(&params, "", &result);
    int wrapper_token = YYPSLR_PSEUDO_SCAN(&params, "", &match_length);
    int ok = token == YYEOF && result.token == YYEOF && wrapper_token == YYEOF &&
      result.length == 0 && result.is_layout == 0 && result.is_character_token == 0 &&
      match_length == 0;

    printf("%s %d %d %d %d\n", ok ? "EOF" : "BAD", result.length, result.is_layout,
      result.is_character_token, match_length);
    return ok ? 0 : 1;
  }

  if (argc == 2) {
    yy_scan_string(argv[1]);
  }

  return yyparse(&params);
}
