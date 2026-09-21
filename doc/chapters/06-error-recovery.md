# Error Recovery and Error Tolerance

Lrama supports ordinary grammar-level error recovery and an error-tolerant parser mode.

## The `error` Token

Use the special `error` token in a rule to recover from syntax errors:

```bison
program:
    expr
  | error { yyerrok; }
  ;
```

This follows the familiar LR parser pattern: when a syntax error occurs, the parser looks for a state that can shift `error`, then continues from there.

## Error-Tolerant Mode

Pass `-e` to enable Lrama's error recovery support in generated output:

```shell
$ bundle exec ruby exe/lrama -e -d grammar.y -o parser.c
```

The implementation is intended for error-tolerant parsing work such as CRuby parser development. It is based on a subset of the repair approach described in Lrama's README.

## `%error-token`

`%error-token` associates code with symbols or tags for error-token handling:

```bison
%error-token {
    $$ = 100;
} NUM
```

See `spec/fixtures/integration/error_recovery.y` for a test-backed example.

## Hook Directives

The following Lrama-specific hook directives can be useful while observing generated parser behavior:

```bison
%after-shift callback_name
%before-reduce callback_name
%after-reduce callback_name
%after-shift-error-token callback_name
%after-pop-stack callback_name
```

The `after_shift` fixture shows callback names, signatures, and generated parser interaction.

## Action Guidelines

Actions that run during recovery should avoid assuming that every semantic value was produced by a normal successful parse path. Prefer explicit initialization in recovery alternatives and use `%destructor` where discarded semantic values require cleanup.

## Limitations

Error-tolerant parsing does not make an invalid grammar valid and does not replace grammar-specific recovery rules. Use reports, fixtures, and generated parser tests to verify the actual behavior for each grammar.
