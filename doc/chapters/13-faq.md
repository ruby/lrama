# FAQ

## Is Lrama a complete Bison reimplementation?

No. Lrama supports a Bison-style grammar surface and C parser generation for the project's target use cases. It does not currently provide every Bison parser mode, backend, or directive.

## Can I use an existing Bison grammar unchanged?

Maybe. Common C LALR grammars are often close, but you must check directives, parser options, skeleton assumptions, and generated parser integration. Use the directive and compatibility appendices before relying on unchanged behavior.

## Does the generated parser depend on Ruby?

No. Lrama itself is written in Ruby, but the generated parser is C code. The compiled parser depends on the C code, lexer, and runtime support expected by the grammar.

## What are parameterized rules?

Parameterized rules are Lrama grammar helpers that accept symbols as arguments. They reduce repeated grammar text:

```bison
arguments:
    delimited('(', separated_list(',', argument), ')')
  ;
```

The standard library defines common helpers such as `option`, `list`, and `separated_list`.

## What does `%inline` do?

`%rule %inline` expands a helper rule at each use site instead of keeping it as a separate nonterminal. This can improve readability while preserving the desired parser-state shape.

## How do I investigate conflicts?

Start with:

```shell
$ lrama --report=states,itemsets,lookaheads,solved,counterexamples --report-file=grammar.output grammar.y
```

Then inspect the conflicting states, lookaheads, and whether precedence resolved or failed to resolve the conflict.

## How do I enable error recovery?

Use ordinary grammar `error` token rules, and pass `-e` when you need Lrama's generated error recovery support:

```shell
$ lrama -e grammar.y
```

Use `%error-token` when a grammar needs error-token semantic values for specific symbols.

## What is the difference between `-d` and `-H`?

`-d` enables header generation and lets Lrama derive the header path. `-H` or `--header` also enables header generation and can specify the header path directly.

## Where does `--report` write output?

If `--report` is given without `--report-file`, Lrama writes a `.output` file next to the grammar file. With STDIN mode, it derives the path from the file name supplied after `-`.

## Can I disable the standard library?

Yes. Add `%no-stdlib` to the grammar. You then need to define helpers such as `option(X)` yourself before using suffixes or standard helper names.

## How do I update Lrama in Ruby?

Follow the release flow documented in the repository README. For parser-impacting changes, regenerate parser artifacts, run Lrama tests, and build Ruby with the target branch.
