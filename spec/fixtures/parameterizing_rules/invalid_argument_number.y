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

%token <i> num1
%token <i> num2

%%

program         : list(num1, num2)
                ;

%%

static int yylex(YYSTYPE *yylval, YYLTYPE *loc) {
{
  return 0;
}

static int yyerror(YYLTYPE *loc, const char *str) {
{
  return 0;
}

int main(int argc, char *argv[])
{
}
