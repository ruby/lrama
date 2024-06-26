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

%rule defined_option(X): /* empty */
                       | X
                       ;

%%

program         : defined_option(number) <i>
                | defined_list(number) <i>
                ;

%rule defined_list(X): /* empty */
                     | defined_list(X) number
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
