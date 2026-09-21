# Examples

The `sample/` directory contains complete grammars that are useful both as examples and as smoke tests.

## Calculator

`sample/calc.y` is the smallest complete interactive example. It declares a semantic value union, token types, precedence, locations, an inline operator rule, grammar rules, and C lexer/parser glue.

```shell
$ bundle exec ruby exe/lrama -d sample/calc.y -o /tmp/calc.c
$ gcc -Wall /tmp/calc.c -o /tmp/calc
$ /tmp/calc
Enter the formula:
1+2*3
=> 7
```

The grammar uses `%rule %inline` to replace references to `op` with the operator alternatives before parser states are computed:

```bison
%rule %inline op:
    '+' { + }
  | '-' { - }
  | '*' { * }
  | '/' { / }
  ;
```

## Basic Parser Shape

`sample/parse.y` shows the basic layout:

```bison
%{
/* prologue C code */
%}

%union {
    int i;
}

%token <i> number

%%

program:
    expr
  ;

%%

/* epilogue C code */
```

The first section is declarations, the section after the first `%%` is grammar rules, and the optional section after the second `%%` is copied to the generated C file.

## JSON And SQL

`sample/json.y` demonstrates standard-library parameterized rules:

```bison
object:
    '{' members? '}'
  ;

members:
    separated_nonempty_list(',', pair)
  ;
```

The suffix `?` expands through `option(X)`. The list helper comes from `lib/lrama/grammar/stdlib.y`.

`sample/sql.y` is a larger grammar that is useful when checking grammar organization, generated parser size, and syntax diagram output.

## Syntax Diagrams

Generate an HTML syntax diagram from any grammar:

```shell
$ bundle exec ruby exe/lrama --diagram=/tmp/calc.html sample/calc.y
```

The default diagram output path is `diagram.html` when `--diagram` is used without a file name.

## Reports

Generate a parser report while investigating states or conflicts:

```shell
$ bundle exec ruby exe/lrama -v --report-file=/tmp/calc.output sample/calc.y
```

For more detail:

```shell
$ bundle exec ruby exe/lrama --report=states,itemsets,lookaheads,solved,counterexamples --report-file=/tmp/calc.output sample/calc.y
```

## Error Recovery

The ordinary grammar-level `error` token can be used in rules:

```bison
program:
    expr
  | error { yyerrok; }
  ;
```

Lrama also has an error-tolerant parser mode enabled with `-e`. Fixtures under `spec/fixtures/integration/error_recovery.y` show `%error-token` declarations and generated parser behavior used by the test suite.
