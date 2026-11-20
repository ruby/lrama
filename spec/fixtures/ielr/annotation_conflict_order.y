%define api.pure full
%locations
%code provides {
  static int yylex(YYSTYPE *, YYLTYPE *);
  static void yyerror(YYLTYPE *, const char *);
}
%define lr.type ielr
%token 'a' 'b' 'c' 'd'
%right 'c'
%right 'b'
%precedence 'a'
%%
start: expr | chain;
expr: 'a' expr tail | prefix 'd' | nested 'c';
chain: prefix chain;
tail: 'a' | %empty | expr;
nested: 'c' | 'a' expr tail %prec 'b' | tail 'a';
prefix: tail 'b' | 'a' nested;
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
