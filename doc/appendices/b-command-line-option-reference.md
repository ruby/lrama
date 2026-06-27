# Command Line Option Reference

This table is based on `lib/lrama/option_parser.rb`.

| Option | Argument | Description | Example |
| --- | --- | --- | --- |
| `-S`, `--skeleton=FILE` | File | Use a skeleton other than the default `bison/yacc.c`. | `lrama -S template/bison/yacc.c grammar.y` |
| `-t`, `--debug` | None | Display debugging output from Lrama's internal grammar parser. Equivalent to `-Dparse.trace`. | `lrama -t grammar.y` |
| `--locations` | None | Enable location support. | `lrama --locations grammar.y` |
| `-D`, `--define=NAME[=VALUE]` | Name or name/value | Similar to a `%define` declaration. | `lrama -Dlr.type=ielr grammar.y` |
| `-H`, `--header=[FILE]` | Optional file | Generate a header, optionally at `FILE`. | `lrama -Hparser.h grammar.y` |
| `-d` | None | Generate a header with a derived path. | `lrama -d -o parser.c grammar.y` |
| `-r`, `--report=REPORTS` | Comma-separated words | Generate automaton details. | `lrama --report=states,itemsets grammar.y` |
| `--report-file=FILE` | File | Write report output to `FILE`. | `lrama --report=all --report-file=parser.output grammar.y` |
| `-o`, `--output=FILE` | File | Write generated C output to `FILE`. | `lrama -o parser.c grammar.y` |
| `--trace=TRACES` | Comma-separated words | Write generation traces to standard error. | `lrama --trace=rules,actions grammar.y` |
| `--diagram=[FILE]` | Optional file | Generate an HTML syntax diagram. Defaults to `diagram.html`. | `lrama --diagram=/tmp/grammar.html grammar.y` |
| `--profile=PROFILES` | Comma-separated words | Profile parser generation. | `lrama --profile=call-stack grammar.y` |
| `-v`, `--verbose` | None | Same as adding the `states` report. | `lrama -v grammar.y` |
| `-W`, `--warnings` | None | Enable warnings. | `lrama -W grammar.y` |
| `-e` | None | Enable error recovery support in generated output. | `lrama -e grammar.y` |
| `-V`, `--version` | None | Print version and exit. | `lrama --version` |
| `-h`, `--help` | None | Print help and exit. | `lrama --help` |

## Report Keywords

| Keyword | Meaning |
| --- | --- |
| `states` | Describe parser states. |
| `itemsets` | Include complete item-set closures. |
| `lookaheads` | Show lookahead tokens for reduce items. |
| `solved` | Describe solved shift/reduce conflicts. |
| `counterexamples`, `cex` | Generate conflict counterexamples. |
| `rules` | List unused rules. |
| `terms` | List unused terminals. |
| `verbose` | Include detailed internal state and analysis information. |
| `all` | Enable all report keywords above. |
| `none` | Disable reports. |

The default report option set contains the grammar report internally. A report file is written when `--report`, `-v`, or `--report-file` causes a report path to be present.

## Trace Keywords

| Keyword | Meaning |
| --- | --- |
| `automaton` | Trace states. |
| `closure` | Trace item-set closure computation. |
| `rules` | Trace grammar rules. |
| `only-explicit-rules` | Trace only rules written explicitly in the grammar. |
| `actions` | Trace grammar rules with actions. |
| `time` | Trace generation time. |
| `all` | Enable all supported trace keywords except `only-explicit-rules`. |
| `none` | Disable traces. |

The validator knows additional Bison trace names, but only the keywords listed above are supported by the current Lrama tracer.

## Profile Keywords

| Keyword | Meaning |
| --- | --- |
| `call-stack` | Use the sampling call-stack profiler. |
| `memory` | Use the memory profiler. |

## Defaults And Derived Paths

| Setting | Default |
| --- | --- |
| Output file | `y.tab.c` |
| Skeleton | `bison/yacc.c` |
| Diagram file | `diagram.html` |
| Header path with `-d -o parser.c` | `parser.h` |
| Header path with `-d grammar.y` | `grammar.h` |
| Report path with `--report=all grammar.y` | `grammar.output` |

## STDIN Mode

Use:

```shell
$ lrama [options] - FILE
```

Lrama reads grammar text from standard input and uses `FILE` for diagnostics and derived paths.
