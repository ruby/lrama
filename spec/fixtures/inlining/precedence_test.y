/*
 * Test case for precedence inheritance through inline expansion.
 * This is the core use case of Menhir's %inline feature.
 *
 * Problem: expression op expression has undefined precedence because
 *          op is a nonterminal.
 *
 * Solution: %inline op expands to put PLUS/TIMES directly in the rule,
 *           allowing precedence to be inherited from the terminal.
 */

%{
// Prologue
static int yylex(YYSTYPE *val, YYLTYPE *loc);
static int yyerror(YYLTYPE *loc, const char *str);
%}

%union {
    int i;
}

%token <i> NUM
%token PLUS TIMES

%left PLUS
%left TIMES

%type <i> expression

%rule %inline op: PLUS { $$ = add; }
               | TIMES { $$ = mul; }
               ;

%%

expression: NUM { $$ = $1; }
          | expression op expression { $$ = $1 $2 $3; }
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
