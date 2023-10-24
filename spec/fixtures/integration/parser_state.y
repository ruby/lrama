%{

#define YYDEBUG 1

#include <stdio.h>
#include "parser_state.h"
#include "parser_state-lexer.h"

static int yyerror(YYLTYPE *loc, const char *str);

%}

%union {
    int i;
    char *str;
}

%expect 0

%parser-state in_rescue (before_rescue, after_rescue, after_else, after_ensure)
%parser-state in_def (in_def, not_in_def)
%parser-state in_class (in_class, not_in_class)

%token <i> keyword_begin keyword_end keyword_rescue keyword_else keyword_ensure keyword_class keyword_def
%token <i> NUM
%token <str> cname fname
%token tLSHFT "<<"

%%

program : %parser-state-set(in_rescue, before_rescue)
          %parser-state-set(in_def, not_in_def)
          %parser-state-set(in_class, not_in_class)
            {
              printf("0 => in_def: %s, in_class: %s.\n", YY_CURRENT_STATE_IN_DEF_NAME, YY_CURRENT_STATE_IN_CLASS_NAME);
            }
            {
              printf("0 => %s\n", YY_CURRENT_STATE_IN_RESCUE_NAME);
            }
          bodystmt
            {
              printf("1 => %s\n", YY_CURRENT_STATE_IN_RESCUE_NAME);
            }
        ;

bodystmt : compstmt
             { printf("2 => %s\n", YY_CURRENT_STATE_IN_RESCUE_NAME); }
           opt_rescue
             { printf("3 => %s\n", YY_CURRENT_STATE_IN_RESCUE_NAME); }
           opt_else
             { printf("4 => %s\n", YY_CURRENT_STATE_IN_RESCUE_NAME); }
           opt_ensure
             { printf("5 => %s\n", YY_CURRENT_STATE_IN_RESCUE_NAME); }
         ;

opt_rescue : keyword_rescue %parser-state-push(in_rescue, after_rescue)
             { printf("6 => %s\n", YY_CURRENT_STATE_IN_RESCUE_NAME); }
             compstmt %parser-state-pop(in_rescue)
             { printf("7 => %s\n", YY_CURRENT_STATE_IN_RESCUE_NAME); }
           | /* empty */
           ;

opt_else   : keyword_else %parser-state-set(in_rescue, after_else) compstmt
           | /* empty */
           ;

opt_ensure : keyword_ensure %parser-state-set(in_rescue, after_ensure) compstmt
           | /* empty */
           ;

compstmt : stmts
         ;

stmts : /* empty */
      | stmt
      | stmts ';' stmt
      ;

stmt : primary
     | keyword_begin bodystmt keyword_end
     ;

primary : NUM { printf("NUM => %d\n", $1); }
        | keyword_class
          %parser-state-push(in_def, not_in_def)
          %parser-state-push(in_class, in_class)
          cname
            {
              printf("1. cname => %s. in_def: %s, in_class: %s.\n", $4, YY_CURRENT_STATE_IN_DEF_NAME, YY_CURRENT_STATE_IN_CLASS_NAME);
            }
          compstmt
          keyword_end
          %parser-state-pop(in_def)
          %parser-state-pop(in_class)
            {
              printf("2. cname => %s. in_def: %s, in_class: %s.\n", $4, YY_CURRENT_STATE_IN_DEF_NAME, YY_CURRENT_STATE_IN_CLASS_NAME);
            }
        | keyword_def
          %parser-state-push(in_def, in_def)
          %parser-state-push(in_class, not_in_class)
          fname
            {
              printf("1. fname => %s. in_def: %s, in_class: %s.\n", $4, YY_CURRENT_STATE_IN_DEF_NAME, YY_CURRENT_STATE_IN_CLASS_NAME);
            }
          compstmt
          keyword_end
          %parser-state-pop(in_def)
          %parser-state-pop(in_class)
            {
              printf("2. fname => %s. in_def: %s, in_class: %s.\n", $4, YY_CURRENT_STATE_IN_DEF_NAME, YY_CURRENT_STATE_IN_CLASS_NAME);
            }
        ;

%%

static int yyerror(YYLTYPE *loc, const char *str) {
    fprintf(stderr, "parse error: %s\\n", str);
    return 0;
}

int main(int argc, char *argv[]) {
    yydebug = 1;

    if (argc == 2) {
        yy_scan_string(argv[1]);
    }

    yyparse();
    return 0;
}
