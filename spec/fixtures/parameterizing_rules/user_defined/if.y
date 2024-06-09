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

%token <i> number

%rule defined_rule(X, condition): /* empty */
                                | X { $$ = $1; } %if(condition)
                                | %if(condition) X %endif X { $$ = $1; }
                                ;

%%

r_true        : defined_rule(number, %true)
              ;

r_false       : defined_rule(number, %false)
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
