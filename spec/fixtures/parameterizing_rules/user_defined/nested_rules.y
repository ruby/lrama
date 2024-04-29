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

%rule nested_nested_option(X): /* empty */
                              | X
                              ;

%rule nested_option(X): /* empty */
                       | nested_nested_option(X)
                       ;

%rule option(Y): /* empty */
               | nested_option(Y)
               ;

%%

program         : option(number)
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
