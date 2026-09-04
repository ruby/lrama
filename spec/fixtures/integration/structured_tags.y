%{
#include <stdio.h>
%}

%define api.pure full
%locations
%code requires {
  struct value { int integer; };
}
%union {
  struct value value;
  struct value *pointer;
}
%code provides {
  static int yylex(YYSTYPE *, YYLTYPE *);
  static void yyerror(YYLTYPE *, const char *);
}

%token <value.integer> NUMBER
%token <pointer->integer> POINTER
%type <value.integer> result
%destructor { printf("discard %d\n", $$); } <value.integer>

%%

start: result { printf("result %d\n", $1); };
result: NUMBER[n] POINTER[p] { $<value.integer>$ = $<value.integer>n + $<pointer->integer>[p]; };

%%

static int yylex(YYSTYPE *value, YYLTYPE *location)
{
  static int count;
  static struct value pointed = { 5 };
  (void) location;
  switch (count++) {
    case 0: value->value.integer = 7; return NUMBER;
    case 1: value->pointer = &pointed; return POINTER;
    default: return 0;
  }
}

static void yyerror(YYLTYPE *location, const char *message)
{
  (void) location;
  fprintf(stderr, "%s\n", message);
}

int main(void)
{
  return yyparse();
}
