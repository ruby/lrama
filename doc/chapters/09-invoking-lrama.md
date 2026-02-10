# Invoking Lrama

Lrama is a command-line tool that reads a grammar file and emits parser code.

```shell
$ lrama [options] FILE
```

## Common options

- `-o, --output=FILE`: write parser output to FILE.
- `-H, --header=FILE`: also produce a header file named FILE.
- `-d`: emit `y.tab.h` next to the output file.
- `-v, --verbose`: same as `--report=state`.
- `-r, --report=REPORTS`: emit reports (`states`, `rules`, `counterexamples`,
  etc.).
- `--report-file=FILE`: write report output to FILE.
- `--diagram[=FILE]`: generate HTML grammar diagrams.
- `--trace=TRACES`: print generation traces.
- `-e`: enable error recovery.

Run `lrama --help` to see the full list of options.
