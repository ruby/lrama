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
    char* s;
}

%token <i> number
%token <s> string

%rule nested_multi_option(X): /* empty */
                              | X
                              ;

%rule multi_option(X, Y): /* empty */
                        | nested_multi_option(X)
                        | nested_multi_option(Y) X
                        ;

%%

program         : multi_option(number, string)
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
