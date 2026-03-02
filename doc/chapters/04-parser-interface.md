# Parser Interface

Lrama generates a C parser that follows the same API style as Bison’s default
C interface. The entry point is `yyparse`, which calls `yylex` to obtain tokens
from the lexer and uses `yyerror` for error reporting.

## Required functions

- `int yylex(void)` returns the next token and sets semantic values.
- `int yyparse(void)` drives the parser.
- `void yyerror(const char *message)` reports syntax errors.

The signatures may vary if you configure `%parse-param` or `%lex-param`
arguments in your grammar.

## Location tracking

Location tracking is always enabled in Lrama’s compatibility model. Use `@n`
for the location of a right-hand side symbol and `@$` for the location of the
left-hand side. Define a location type via `%define api.location.type` or by
customizing the generated code.

## Header generation

Use `-d` or `-H` to emit a header file containing token definitions and shared
structures:

```shell
$ lrama -d sample/parse.y
```

## Pure parser assumptions

Lrama assumes a pure parser (`b4_pure_if` is always true). This means semantic
value and location information are passed explicitly rather than using globals.
