# Error Recovery

Lrama supports error tolerant parsing inspired by the algorithm described in
*Repairing Syntax Errors in LR Parsers*.

## Enabling recovery

Pass `-e` when generating the parser to enable recovery support.

```shell
$ lrama -e sample/parse.y
```

## Writing recovery rules

Use the special `error` token in grammar rules to specify recovery points. A
common pattern is to skip to a statement terminator or newline.

```yacc
statement:
    expr ';'
  | error ';' { /* discard the rest of the statement */ }
  ;
```

## Handling recovery in actions

Make sure semantic actions can cope with partially parsed input. Keep actions
small and defensively check inputs for null values when necessary.
