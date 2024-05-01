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

%rule with_tag(X) <i>: X { $$ = $1; }
                      ;

%%

program         : with_tag(number)
                | with_tag(string) <s>
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
