%{
#include <stdio.h>
%}

%define api.pure full
%locations
%define parse.error verbose
%code provides {
  static int yylex(YYSTYPE *, YYLTYPE *);
  static void yyerror(YYLTYPE *, const char *);
}

%token A 259
%token B C

%%

start: A B C { puts("accepted"); };

%%

static int yylex(YYSTYPE *value, YYLTYPE *location)
{
  static const int tokens[] = { A, B, C, 0 };
  static int index;
  (void) value;
  (void) location;
  return tokens[index++];
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
