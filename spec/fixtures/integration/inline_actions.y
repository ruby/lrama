%{
#include <stdio.h>
static int calls;
#define YYLLOC_DEFAULT(Current, Rhs, N) do {                                   \
  (Current).first_line = 1;                                                    \
  (Current).last_line = (Rhs)[N].last_line + (N);                              \
  (Current).first_column = (N) ? (Rhs)[1].first_column : (Rhs)[0].last_column; \
  (Current).last_column = (Rhs)[N].last_column;                                \
} while (0)
%}
%code provides {
  static int yylex(YYSTYPE *, YYLTYPE *);
  static void yyerror(YYLTYPE *, const char *);
}
%locations
%expect 0
%union { int i; }
%token <i> NUM
%type <i> delegated updated

%rule %inline right : 'a' 'b' { @$ = @1; } | %empty { @$.last_column += 5; };
%rule %inline endpoint : right;
%rule %inline inc <i> : NUM { $$ += 1; };
%rule %inline increment <i> : inc { $$ += 1; };
%rule %inline pair <i>: NUM NUM { $$ = $1 * 100 + $2; };
%rule %inline unit <i>: NUM { ++calls; $$ = $1 * 10; };
%rule %inline nested <i>: unit { $$ = $1 + 1; };
%rule %inline sign <i>: %empty { $$ = 0; } | '-' { $$ = 1; };
%rule %inline span: %empty { printf("%d..%d", @$.first_column, @$.last_column); }
                  | 'a' 'b' { printf("%d..%d", @$.first_column, @$.last_column); @$ = @2; };

%%
start: NUM pair NUM NUM { printf("%d", $1 + $2 + $3 * 10 + $4); }
     | 'u' nested { printf("%d", @2.last_line); }
     | 'c' wrapped { printf("%d", @2.last_line); }
     | 'x' wrapped { printf("%d..%d", @2.first_column, @2.last_column); }
     | 'y' checked { printf(" %d..%d", @2.first_column, @2.last_column); }
     | 'v' updated { printf("%d", $2); }
     | 'n' nested[value] { printf("%d %d %d", $value, $value, calls); }
     | 'd' delegated { printf("%d %d", $2, calls); }
     | 's' sign unit { printf("%d %d", $2, $3); }
     | 'l' span NUM { printf(" %d..%d", @2.first_column, @2.last_column); }
     | 'm' pair[p] nested[value] { printf("%d/%d/%d[%d..%d] ", $p, $value, calls, @p.first_column, @value.last_column); }
       NUM { printf("%d/%d/%d", $2, $3, $5); }
     | 'k' ioption('-') NUM { printf("%d ", $3); } NUM { printf("%d", $5); }
     | 'o' ioption('-') NUM { printf("%d", $3); }
     ;
delegated: unit;
wrapped: 'p' endpoint;
checked: 'p' endpoint { printf("%d..%d", @$.first_column, @$.last_column); };
updated: increment { $$ += 1; };
%%
static const char *input;
static int column;

static int yylex(YYSTYPE *value, YYLTYPE *location) {
  int c = input[column];
  if (!c) return 0;
  location->first_line = location->last_line = 1;
  location->first_column = column++;
  location->last_column = column;
  if (c >= '0' && c <= '9') {
    value->i = c - '0';
    return NUM;
  }
  return c;
}

static void yyerror(YYLTYPE *location, const char *message) {
  fprintf(stderr, "%d: %s\n", location->first_column, message);
}

int main(int argc, char **argv) {
  if (argc != 2) return 2;
  input = argv[1];
  return yyparse();
}
