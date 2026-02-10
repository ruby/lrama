# Parser Algorithm

Lrama produces LALR(1) parsers. The generated parser uses the standard LR
algorithm with shift/reduce and reduce/reduce conflict resolution.

## Conflicts and precedence

Use `%left`, `%right`, and `%precedence` declarations to resolve
shift/reduce conflicts. Lrama reports conflicts in the `--report` output and
with `-v` (alias for `--report=state`).

## Reports and diagnostics

Lrama can emit detailed state and conflict reports during parser generation.
Common report options include:

- `--report=state`: state machine summary (also `-v`).
- `--report=counterexamples`: generate conflict counterexamples.
- `--report=all`: include all reports.

You can write the report to a file with `--report-file`.

```shell
$ lrama -v --report-file=parser.report sample/parse.y
```

## Error tolerant parsing

When `-e` is supplied, Lrama enables its error recovery extensions. This uses a
subset of the algorithm described in *Repairing Syntax Errors in LR Parsers*.
Refer to [Error Recovery](06-error-recovery.md) for guidance on structuring
rules.
