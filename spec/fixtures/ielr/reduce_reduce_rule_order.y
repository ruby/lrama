%define api.pure full
%locations
%code provides {
  static int yylex(YYSTYPE *, YYLTYPE *);
  static void yyerror(YYLTYPE *, const char *);
}
%%
start: 'a' empty 'b' 'x' | direct 'b' 'y';
empty: %empty;
direct: 'a';
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
