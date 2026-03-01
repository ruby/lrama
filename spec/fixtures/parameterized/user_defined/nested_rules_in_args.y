/*
 * This is comment for this file.
 */

%{
static int yylex(YYSTYPE *val, YYLTYPE *loc);
static int yyerror(YYLTYPE *loc, const char *str);
%}

%union {
    int i;
    char *s;
}

%token <i> number
%token <s> string

%rule f_opt(X): /* empty */
              | X
              ;

%rule opt_tail(X): /* empty */
                 | X
                 ;

%rule args_list(X, Y, Z): X
                         | Y
                         | Z
                         ;

%%

program         : args_list(f_opt(number), opt_tail(string), number)
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
