# Troubleshooting

## `File should be specified`

No grammar file argument was passed.

```shell
$ lrama grammar.y
```

## `File name for STDIN should be specified`

STDIN mode was requested with `-`, but no file name was supplied after it.

```shell
$ cat grammar.y | lrama - grammar.y
```

The second `grammar.y` is used for diagnostics and derived output paths.

## `Invalid report option`

The value passed to `--report` is not one of Lrama's supported report keywords. Check [Command Line Option Reference](b-command-line-option-reference.md#report-keywords).

## `Invalid trace option`

The value passed to `--trace` is not one of the currently supported trace keywords. The supported set is `automaton`, `closure`, `rules`, `only-explicit-rules`, `actions`, `time`, `all`, and `none`.

## A Header Was Not Generated

Pass `-d`, `-H`, or `--header`:

```shell
$ lrama -d -o parser.c grammar.y
$ lrama --header=parser.h -o parser.c grammar.y
```

## The Generated C File Does Not Compile

Check these points first:

- Does the grammar declare `%union` and symbol tags consistently?
- Does `yylex` use the signature implied by locations and `%lex-param`?
- Does `yyerror` use the signature implied by locations and `%parse-param`?
- Is the generated header included by the lexer?
- Are required C headers and macros in the prologue?

## Conflicts Appeared

Generate a detailed report:

```shell
$ lrama --report=states,itemsets,lookaheads,solved,counterexamples --report-file=grammar.output grammar.y
```

Then check whether the conflict is real grammar ambiguity, missing precedence, an accidental nullable rule, or a helper rule that should be inlined.

## `%empty on non-empty rule`

`%empty` can only appear in an empty alternative. Split the rule so the empty case is its own alternative:

```bison
list:
    %empty
  | list item
  ;
```

## `multiple %prec in a rule`

Only one `%prec` is allowed for an alternative. Keep the final intended override.

## A Standard-Library Rule Name Conflicts With My Grammar

Use a different user rule name, or declare `%no-stdlib` and define the parameterized rules you need manually. Enabling `-W` can help find name conflicts.

## Syntax Diagrams Are Missing

Pass `--diagram`:

```shell
$ lrama --diagram=/tmp/grammar.html grammar.y
```

Without an explicit path, Lrama writes `diagram.html`.
