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
    char *s;
}

%token <i> number
%token <s> string

%rule defined_option(X): /* empty */
                       | X
                       ;

%rule multi_args(X, Y): X
                      | Y
                      ;

%rule unused_define(X): /* empty */
                      | X
                      ;

%rule pair(X, Y): X ',' Y { printf("(%d, %d)\n", $1, $2); }
                ;

%%

program         : defined_option(number) <i>
                | multi_args(number, string)
                | multi_args(number, number)
                | pair(number, string) { printf("pair odd even\n"); }
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
