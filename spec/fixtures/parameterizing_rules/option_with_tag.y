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
%token <i> number_alias

%%

program         : option(number) <i>
                ;

alias           : number_alias? <i>
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
