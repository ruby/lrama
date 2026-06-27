# Invoking Lrama

The command form is:

```shell
$ lrama [options] FILE
```

From a repository checkout, use:

```shell
$ bundle exec ruby exe/lrama [options] FILE
```

## STDIN Mode

Use `-` to read the grammar text from standard input. A grammar file name must still be supplied after `-`; Lrama uses that name for diagnostics and default output paths.

```shell
$ cat sample/calc.y | bundle exec ruby exe/lrama -o /tmp/calc.c - /tmp/calc.y
```

If no grammar file is specified, Lrama exits with:

```text
File should be specified
```

If `-` is used without a file name, it exits with:

```text
File name for STDIN should be specified
```

## Output Options

The default output file is `y.tab.c`.

```shell
$ lrama grammar.y
$ lrama -o parser.c grammar.y
```

Use `-d` to also generate a header. Use `-H` or `--header` to choose the header path:

```shell
$ lrama -d -o parser.c grammar.y
$ lrama --header=parser.h -o parser.c grammar.y
```

When the header path is omitted, Lrama derives it from the output file if `-o` was used, otherwise from the grammar file.

## Reports

Use `--report=REPORTS` or `-r REPORTS` for automaton details:

```shell
$ lrama --report=states,itemsets,lookaheads --report-file=parser.output grammar.y
```

`-v` is equivalent to adding the `states` report.

## Traces

Use `--trace=TRACES` for generation traces:

```shell
$ lrama --trace=rules,actions grammar.y
```

Use `--trace=time` to include generation timing.

## Diagrams

Use `--diagram` to write `diagram.html`, or pass a path:

```shell
$ lrama --diagram grammar.y
$ lrama --diagram=/tmp/grammar.html grammar.y
```

## Error Recovery

Use `-e` to enable error recovery support in generated output:

```shell
$ lrama -e grammar.y
```

## Defines

Use `-D` or `--define` to pass a value equivalent to a `%define` declaration:

```shell
$ lrama -Dparse.trace grammar.y
$ lrama --define=lr.type=ielr grammar.y
```

Multiple comma-separated values are accepted by Ruby's option parser for array options.

## Help And Version

```shell
$ lrama --help
$ lrama --version
```

See [Command Line Option Reference](../appendices/b-command-line-option-reference.md) for the complete option table.
