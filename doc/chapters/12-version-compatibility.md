# Version Compatibility

Lrama compatibility has three practical dimensions: the Lrama version, the Ruby version that runs Lrama, and the CRuby branch that consumes generated parser output.

## Ruby Runtime

Lrama is executed with BASERUBY while building Ruby from source. It must support the BASERUBY version used by that Ruby branch and must run with default gems only because BASERUBY is invoked with `--disable=gems`.

## Branches

The README documents these branch relationships:

| Branch | Target |
| --- | --- |
| `master` / v0_8 | Ruby 4.1 development |
| `lrama_0_7` / v0_7 | Ruby 4.0 |
| `lrama_0_6` / v0_6 | Ruby 3.4 |
| `lrama_0_5` / v0_5 | Ruby 3.3 |
| `lrama_0_4` / v0_4 | Ruby 3.0, 3.1, and 3.2 Bison-compatible parser generation |

Check the README on the branch you are using. Branch purpose can change as Ruby release lines move.

## Bison Compatibility

Lrama accepts a focused Bison-style grammar subset and generates Bison-like C parser artifacts, but it is not a complete Bison replacement for every language backend or parser mode.

Before moving a grammar from Bison to Lrama:

1. Check directives against [Directive Reference](../appendices/a-directive-reference.md).
2. Check command options against [Command Line Option Reference](../appendices/b-command-line-option-reference.md).
3. Generate parser reports with both tools when possible.
4. Compile and run parser integration tests.
5. Confirm legal and template implications using [License and Legal Notes](../appendices/g-license-and-legal-notes.md).

## Migration Checklist

- Run Lrama with `-W` and address warnings.
- Generate `--report=states,itemsets,lookaheads,solved,counterexamples`.
- Compare expected conflicts against `%expect`.
- Compile with the same C compiler flags as the target project.
- Run syntax error and recovery tests, not only successful parse tests.
- Regenerate syntax diagrams for review if the grammar is large.
