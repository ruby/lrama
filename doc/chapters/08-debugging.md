# Debugging Your Parser

Lrama provides parser reports, generation traces, warnings, diagrams, and profiling options.

## State Reports

Use `-v` for the standard state report:

```shell
$ bundle exec ruby exe/lrama -v sample/calc.y
```

When `--report` is used and no `--report-file` is given, Lrama writes a report next to the grammar file using the `.output` extension. Use `--report-file` to choose the path:

```shell
$ bundle exec ruby exe/lrama --report=states,itemsets,lookaheads --report-file=/tmp/calc.output sample/calc.y
```

Report keywords are listed in [Command Line Option Reference](../appendices/b-command-line-option-reference.md).

## Conflict Investigation

Start with:

```shell
$ bundle exec ruby exe/lrama --report=states,lookaheads,solved,counterexamples --report-file=/tmp/report.output grammar.y
```

Then inspect:

- The state that reports the conflict.
- The lookahead token or tokens involved.
- Whether precedence solved part of the conflict.
- Counterexamples when `counterexamples` or `cex` is enabled.

If a conflict should be resolved by precedence, check the order of `%left`, `%right`, `%nonassoc`, and `%precedence` declarations and whether the rule inherits the expected terminal precedence. Use `%prec` when the rule needs a different precedence.

## Generation Traces

Use `--trace` for generation-time traces written to standard error:

```shell
$ bundle exec ruby exe/lrama --trace=rules,actions sample/calc.y
```

Supported trace keywords are `automaton`, `closure`, `rules`, `only-explicit-rules`, `actions`, `time`, `all`, and `none`.

## Syntax Diagrams

Generate a diagram to review grammar shape visually:

```shell
$ bundle exec ruby exe/lrama --diagram=/tmp/diagram.html sample/calc.y
```

Syntax diagrams are useful when reviewing grammar changes with people who do not want to read parser states.

## Warnings

Enable warnings with:

```shell
$ bundle exec ruby exe/lrama -W grammar.y
```

Warnings cover cases such as useless precedence, required-version declarations that have no effect, redefined parameterized rules, name conflicts, and implicit empty rules.

## Profiling

Use profiling options while working on parser generation performance:

```shell
$ bundle exec ruby exe/lrama --profile=call-stack grammar.y
$ bundle exec ruby exe/lrama --profile=memory grammar.y
```

The profile modes depend on optional profiling libraries. See [Profiling](../development/profiling.md) for development notes.
