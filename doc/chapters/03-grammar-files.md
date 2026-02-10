# Grammar Files

Lrama reads Bison-style grammar files. Each grammar file has four sections in
order:

1. **Prologue**: C code copied verbatim into the generated parser.
2. **Declarations**: Bison-style directives such as `%token` and `%start`.
3. **Grammar rules**: The productions and semantic actions.
4. **Epilogue**: C code appended to the end of the generated parser.

A minimal grammar looks like this:

```yacc
%token INTEGER
%%
input: INTEGER '\n';
%%
```

## Symbols

- **Terminals** are tokens returned by the lexer.
- **Nonterminals** are syntactic groupings defined by rules.

Lrama accepts the common `%token`, `%type`, `%left`, `%right`, and
`%precedence` declarations in the declarations section.

## Rules and actions

Grammar rules use the standard Bison syntax. Semantic actions are C code blocks
that run when a rule is reduced.

```yacc
expr:
    expr '+' expr { $$ = $1 + $3; }
  | INTEGER       { $$ = $1; }
  ;
```

## Parameterized rules

Lrama extends Bison-style rules with parameterization. A nonterminal definition
may accept other symbols as parameters, allowing you to reuse rule templates.
Parameterized rules are defined with `%rule` and invoked like a nonterminal.

```yacc
%rule option(X)
  : /* empty */
  | X
  ;

program:
    option(statement)
  ;
```

When Lrama expands a parameterized rule, it creates a concrete nonterminal
whose name encodes the parameters. The example above expands to a rule named
`option_statement`.

### Parameterized rules in the standard library

Lrama ships a standard library of reusable parameterized rules in
[`lib/lrama/grammar/stdlib.y`](../../lib/lrama/grammar/stdlib.y). Common
patterns include:

- `option(X)`: optional symbol.
- `list(X)`: zero or more repetitions.
- `nonempty_list(X)`: one or more repetitions.
- `separated_list(separator, X)`: separated list with optional empty case.
- `separated_nonempty_list(separator, X)`: separated list with at least one
  element.
- `delimited(opening, X, closing)`: wrap a symbol with delimiters.

You can reference these directly by including the standard library in your
grammar or copy them into your own grammar file.

### Semantic values and locations

Parameterized rules support the same semantic action syntax as ordinary rules.
If you add actions to a parameterized rule, the generated nonterminal keeps the
action and location references intact. When you call a parameterized rule, the
resulting nonterminal can be used like any other symbol in subsequent rules.

## Inlining

The `%inline` directive replaces all references to a symbol with its
definition. It is useful for eliminating extra nonterminals, removing
shift/reduce conflicts, or keeping small helper rules from polluting the symbol
list.

```yacc
%inline opt_newline
  : /* empty */
  | '\n'
  ;

lines:
    lines opt_newline line
  | line
  ;
```

An inline rule does not create a standalone nonterminal in the output. Instead,
its productions are substituted wherever the inline symbol is referenced. This
is why `%inline` is often paired with parameterized rules (for example,
`%inline ioption(X)` in the standard library) to build reusable templates
without growing the symbol table.

## Error recovery

Use `error` tokens in rules and enable recovery with `-e` when generating the
parser. For guidance, see the [Error Recovery](06-error-recovery.md) chapter.
