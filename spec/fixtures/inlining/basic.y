/*
 * This is comment for this file.
 */

%{
// Prologue
static int yylex(YYSTYPE *val, YYLTYPE *loc);
static int yyerror(YYLTYPE *loc, const char *str);
%}

%union {
    int i;
}

%token <i> NUM
%type <i> expression

%rule %inline op  : '+' { + }
                  | '-' { - }
                  | '*' { * }
                  | '/' { / }
                  ;

%%

expression      : NUM
                | expression op expression { $$ = $1 $2 $3; }
                | expression other_op expression { $$ = $1 $2 $3; }
                ;


%rule %inline other_op : '%' { + 1 + }
                       | '&' { - 1 - }
                       ;

%%

static int yylex(YYSTYPE *yylval, YYLTYPE *loc)
{
  return 0;
}

static int yyerror(YYLTYPE *loc, const char *str)
{
  return 0;
}

int main(int argc, char *argv[])
{
}
