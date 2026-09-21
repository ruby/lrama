# Parser Algorithm

Lrama builds LR parser states from grammar rules, computes transitions, resolves conflicts when possible, and renders compact parser tables for the C skeleton.

## States And Items

An LR item is a rule with a position marker:

```text
expr: expr '+' * expr
```

The marker shows how much of the rule has been recognized. A parser state is a set of items. Transitions between states are labeled by grammar symbols.

Use `--report=states,itemsets` to inspect states and complete item sets:

```shell
$ bundle exec ruby exe/lrama --report=states,itemsets --report-file=/tmp/calc.output sample/calc.y
```

## Lookahead

LALR(1) parsing uses one lookahead token to decide whether to shift a token, reduce by a rule, accept the input, or report an error. Use `--report=lookaheads` to show lookahead tokens associated with reduce items.

## Shift And Reduce

A shift consumes the lookahead token and moves to another state. A reduce replaces symbols on the parser stack with the left-hand side of a matched rule.

Reports show both actions:

```text
'+'  shift, and go to state 7
$default  reduce using rule 3 (expr)
```

## Conflicts

A shift/reduce conflict means the parser can either shift the lookahead token or reduce by a rule. A reduce/reduce conflict means more than one rule can reduce for the same lookahead.

Use:

```shell
$ bundle exec ruby exe/lrama --report=states,lookaheads,solved,counterexamples --report-file=/tmp/report.output grammar.y
```

Precedence declarations can resolve many expression grammar conflicts:

```bison
%left '+' '-'
%left '*' '/'
```

Rules inherit precedence from the last terminal in the right-hand side unless `%prec` specifies a different symbol.

## IELR

Lrama can compute IELR tables when requested by the grammar:

```bison
%define lr.type ielr
```

The integration fixture `spec/fixtures/integration/ielr.y` demonstrates this mode. Treat IELR as an explicit grammar choice and verify the resulting reports and generated parser.

## Table Generation

After states are computed, Lrama builds the parser context used by the skeleton. The generated C file contains arrays for parser actions, gotos, reductions, symbol names, rule lines, and related metadata. The exact array set is an implementation detail of the selected skeleton.
