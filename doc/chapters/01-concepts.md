# Concepts

Lrama uses the same core vocabulary as LR parser generators such as Yacc and Bison.

## Grammar

A grammar describes a language as a set of symbols and rules. A rule has a left-hand side nonterminal and one or more right-hand side alternatives:

```bison
expr:
    NUM
  | expr '+' expr
  ;
```

Lrama reads a grammar file, resolves symbols and rules, computes parser states, and emits parser tables plus skeleton code.

## Terminals And Nonterminals

A terminal is a token returned by the lexer. Terminals are declared with directives such as `%token`, `%left`, `%right`, `%nonassoc`, and `%precedence`, or they appear as character literals such as `'+'`.

A nonterminal is a grammar symbol defined by rules. Nonterminals can be typed with `%type` or `%nterm`.

## Tokens

The generated parser calls `yylex` to obtain tokens. A token can carry a semantic value through `YYSTYPE` and, when locations are enabled, a location through `YYLTYPE`.

Lrama adds the special symbols `YYEOF`, `YYerror`, `YYUNDEF`, and `$accept` internally while preparing the grammar.

## Semantic Values And Actions

Semantic actions are C code blocks attached to rules. They compute values with references such as `$$`, `$1`, `$name`, and `$[name-with-dash]`.

```bison
expr:
    expr '+' expr { $$ = $1 + $3; }
  ;
```

When `%union` is declared, symbols should have tags such as `<val>` so Lrama can render the correct union member access. If `%union` is absent, `YYSTYPE` defaults to `int` in the generated skeleton.

## Locations

Locations track source positions. Enable them with `%locations`, `--locations`, or by using location references such as `@1` or `@expr` in actions. Location-aware parsers pass `YYLTYPE *` values to `yylex` and `yyerror`.

## LALR(1)

Lrama generates LALR(1) parser tables by default. An LR parser keeps a stack of states, uses at most one lookahead token to decide what to do next, and performs shift, reduce, accept, or error actions.

IELR generation is available when the grammar defines:

```bison
%define lr.type ielr
```

Use IELR only when the grammar needs it and after checking reports and tests.

## Compatibility Assumptions

Lrama supports Bison-style grammar files with a focused feature set. The README records several skeleton compatibility assumptions, including always-true location and pure-parser branches in the Bison template compatibility layer, no push parser branch, and no LAC branch. Those assumptions do not mean every Bison option is implemented as a user-visible Lrama feature.

When in doubt, check [Directive Reference](../appendices/a-directive-reference.md) and [Bison Compatibility](../appendices/c-bison-compatibility.md).
