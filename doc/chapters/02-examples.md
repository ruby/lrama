# Examples

This chapter mirrors the structure of the Bison manual examples, but focuses on
what is present in the Lrama repository today.

## Calculator example (sample/calc.y)

The [`sample/calc.y`](../../sample/calc.y) grammar is the canonical example
for running Lrama.

```shell
$ lrama -d sample/calc.y -o calc.c
$ gcc -Wall calc.c -o calc
$ ./calc
```

The grammar demonstrates:

- Declaring tokens and precedence.
- Attaching semantic actions in C.
- Generating a header file with `-d`.

## Minimal parser example (sample/parse.y)

[`sample/parse.y`](../../sample/parse.y) is a smaller grammar intended to be
used by the build instructions and smoke tests.

```shell
$ lrama -d sample/parse.y
```

## Additional grammars

The `sample/` directory includes additional grammars that cover different
syntax styles:

- [`sample/json.y`](../../sample/json.y)
- [`sample/sql.y`](../../sample/sql.y)

These are good starting points when verifying compatibility or experimenting
with new directives.
