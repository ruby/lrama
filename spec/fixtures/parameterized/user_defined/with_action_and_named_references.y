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

%rule sum(X, Y) <i>: X[summand] '+' Y[addend] { $$ = $summand + $addend; }
             ;

%%

program         : sum(number, number) { printf("sum number\n"); }
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
