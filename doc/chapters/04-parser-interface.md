# Parser C Interface

Lrama emits a C parser. The exact generated code depends on the skeleton, grammar declarations, and command-line options, but the common interface follows the Bison-style C parser model.

## `yyparse`

The generated parser entry point is `yyparse`.

Without parse parameters:

```c
int yyparse(void);
```

With `%parse-param {int parser_param}`:

```c
int yyparse(int parser_param);
```

The generated header declares `yyparse` when header generation is enabled.

## `yylex`

The parser calls `yylex` to obtain the next token. With semantic values and locations, examples use:

```c
static int yylex(YYSTYPE *yylval, YYLTYPE *yylloc);
```

If `%lex-param` is declared, Lrama passes the extracted parameter name to `yylex`:

```bison
%lex-param {int parser_param}
```

With both locations and the lex parameter, the call shape is:

```c
yylex(&yylval, &yylloc, parser_param)
```

## `yyerror`

The parser calls `yyerror` on syntax errors. With locations and no parse parameter, examples use:

```c
static int yyerror(YYLTYPE *loc, const char *str);
```

With `%parse-param`, Lrama passes the parse parameter before the error string:

```c
static int yyerror(YYLTYPE *loc, int parser_param, const char *str);
```

## Semantic Values

Use `%union` to define `YYSTYPE` and tags on tokens or nonterminals:

```bison
%union {
    int val;
}

%token <val> NUM
%type <val> expr
```

Actions can then assign and read tagged values:

```bison
expr:
    expr '+' expr { $$ = $1 + $3; }
  ;
```

If `%union` is absent, the generated skeleton treats `YYSTYPE` as `int`.

## Locations

Use `%locations`, `--locations`, or action references such as `@1` to enable location support. The default `YYLTYPE` structure includes first and last line and column fields. You can override location behavior with C macros such as `YYLLOC_DEFAULT` in the prologue.

## Header Generation

Use `-d` to generate a header next to the output C file:

```shell
$ bundle exec ruby exe/lrama -d sample/calc.y -o /tmp/calc.c
```

Use `-HFILE` or `--header=FILE` to select the header path:

```shell
$ bundle exec ruby exe/lrama --header=/tmp/calc.h -o /tmp/calc.c sample/calc.y
```

The header contains token definitions, `YYSTYPE`, `YYLTYPE`, and the `yyparse` declaration.

## Pure Parser Assumption

The generated C skeleton defines a pure parser configuration. User code should be written as reentrant parser code: pass scanner or parser state through `%lex-param` and `%parse-param` rather than relying on global parser state when possible.
