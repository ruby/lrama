# Debugging

Lrama offers both generation-time and runtime diagnostics.

## Generator traces

Use `--trace` to print internal generation traces. Useful values are:

- `automaton`: print state transitions.
- `rules`: print grammar rules.
- `actions`: print rules with semantic actions.
- `time`: report generation time.
- `all`: enable all traces.

```shell
$ lrama --trace=automaton,rules sample/parse.y
```

## Reports

`--report` produces structured reports about states, conflicts, and unused
rules/terminals. See [Parser Algorithm](05-parser-algorithm.md) for details.

## Syntax diagrams

Use `--diagram` to emit an HTML diagram of the grammar rules.

```shell
$ lrama --diagram=diagram.html sample/calc.y
```

The repository includes a sample output in [`sample/diagram.html`](../../sample/diagram.html).
