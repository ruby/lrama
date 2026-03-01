/*
 * This is comment for this file.
 */

%{
static int yylex(YYSTYPE *val, YYLTYPE *loc);
static int yyerror(YYLTYPE *loc, const char *str);
%}

%union {
    int i;
}

%token <i> number

%rule option(X): /* empty */
               | X
               ;

%rule pair(X, Y) <i>: option(X)[x] '+' option(Y)[y] { $$ = $x + $y; }
                    ;

%%

program         : pair(number, number)
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
