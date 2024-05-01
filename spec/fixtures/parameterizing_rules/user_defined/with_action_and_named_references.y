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

%rule pair(X, Y): X ',' Y { printf("(%d, %d)\n", $X, $2); }
                ;

%%

program         : pair(number, string) { printf("pair odd even\n"); }
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
