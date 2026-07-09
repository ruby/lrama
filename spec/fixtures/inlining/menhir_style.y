/*
 * Test case for Menhir-style inline action merging.
 * When inline action contains $$, variable binding is used.
 */

%{
// Prologue
static int yylex(YYSTYPE *val, YYLTYPE *loc);
static int yyerror(YYLTYPE *loc, const char *str);
%}

%union {
    int i;
    int (*fn)(int, int);
}

%token <i> NUM
%type <i> expression

/* Menhir-style: inline action returns a value via $$ */
%rule %inline op: '+' { printf("plus\n"); $$ = add; }
               | '*' { printf("times\n"); $$ = mul; }
               ;

%%

expression: NUM { $$ = $1; }
          | expression op expression { $$ = $2($1, $3); }
          ;

%%

static int add(int a, int b) { return a + b; }
static int mul(int a, int b) { return a * b; }

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
