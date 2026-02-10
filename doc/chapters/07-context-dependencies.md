# Handling Context Dependencies

Some grammars are difficult to express with pure context-free rules.
In these cases, the typical approach is to make the lexer or semantic actions
context aware.

## Token-level context

Emit different tokens depending on parser state. For example, you can track
whether you are inside a type declaration and return a distinct token for
identifiers in that context.

## Semantic predicates

Lrama does not provide Bison-style `%prec` predicates or GLR semantic
predicates. Instead, use regular semantic actions and explicit tokens to keep
state.

## Parameterized rules

Parameterized rules can help express repeated patterns without introducing
ambiguity. Use them to factor context-specific constructs while keeping the
grammar readable. See the [Grammar Files](03-grammar-files.md) chapter.
