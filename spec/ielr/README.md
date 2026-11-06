# IELR differential checks

Compare two committed revisions before changing IELR construction:

```sh
ruby spec/ielr/differential.rb master
ruby spec/ielr/differential.rb BASE TARGET --count=250 --seed=0
```

The target defaults to `HEAD`. Uncommitted changes are not included. The runner
uses `git archive` to export both revisions without switching branches or changing
the index. It requires Ruby, Git, and `tar`; it uses the same Ruby executable for
both revisions and clears Bundler's load-path overrides in child processes.

Each run includes the integration IELR grammar, the saved fixtures in
`spec/fixtures/ielr`, and 250 generated grammars by default. Add local benchmark
grammars with repeatable `--grammar` options:

```sh
ruby spec/ielr/differential.rb master \
  --grammar=tmp/ielr/ruby.y --grammar=tmp/ielr/split-heavy.y
```

The comparison covers generated C, all reports except counterexamples, stderr,
and process exit status. Only checkout and output-directory prefixes are normalized; all
other bytes, including source line numbers, remain significant. Missing files
are different from empty files. stdout is saved for diagnosis but not compared.

The runner prints the temporary directory containing both source snapshots and
each grammar's raw outputs. Files are retained after the run for inspection.
Exit codes are:

- `0`: all compared artifacts match.
- `1`: at least one difference, timeout, or signal termination.
- `2`: invalid arguments or a setup error.

Matching nonzero exits are listed separately as `MATCHED FAILURE`; they are not
evidence that a grammar generated successfully. Each invocation has a 30-second
limit, adjustable with `--timeout=SECONDS`. Two timeouts or signal terminations
never count as a match.

Pass `--counterexamples` to use `--report=all`. Its existing internal timeout
diagnostics include iteration counts that vary between runs, so identical
revisions can differ on stderr. The harness deliberately reports these differences
instead of removing non-path text. Inspect the saved outputs before attributing
any difference to an IELR change; a timed-out comparison is inconclusive.

## Reproducible corpus

`grammar.rb` uses a separate `Random.new(seed)` for every grammar. It generates
five terminals and seven nonterminals, terminal productions to ensure
productivity, empty productions, and randomized `%left`, `%right`, `%nonassoc`,
`%precedence`, and `%prec`. Nonterminals only reference later nonterminals, keeping
derivations finite. Recursive grammars need additional fixtures or `--grammar`.

The saved fixtures use this generator's seed sequence:

| Seed | Behavior at `ee571518` |
| --- | --- |
| 22 | `Context#compute_yydefact` raises on a nil reduce lookahead. |
| 108 | IELR splits 20 LALR states into 21 states. |
| 155 | IELR splits 12 LALR states into 13 states. |

These are new reproductions, not the historical seeds 29, 79, and 213 from earlier
experiments: that generator and its output files are unavailable. Seed 22 has a
pending regression example so a future fix makes it fail as unexpectedly passing.

Run the harness and corpus tests with:

```sh
bundle exec rspec spec/ielr
```

The full 250-seed comparison is a manual check. Normal RSpec runs only exercise
the harness and the small fixed corpus, without running the full comparison.
