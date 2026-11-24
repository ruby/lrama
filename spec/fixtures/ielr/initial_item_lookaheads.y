%define lr.type ielr
%define api.pure full
%locations
%code provides {
  static int yylex(YYSTYPE *, YYLTYPE *);
  static void yyerror(YYLTYPE *, const char *);
}
%%
expr: 'd' | term term 'c' | 'c' item item term;
item: 'a' | term 'b';
term: item expr | expr;
%%
static const char *input;

static int yylex(YYSTYPE *value, YYLTYPE *location) {
  (void)value;
  (void)location;
  return *input ? *input++ : 0;
}

static void yyerror(YYLTYPE *location, const char *message) {
  (void)location;
  (void)message;
}

int main(int argc, char **argv) {
  if (argc != 2) return 2;
  input = argv[1];
  return yyparse();
}
