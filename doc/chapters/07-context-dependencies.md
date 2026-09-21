# Context Dependencies

Real language grammars often depend on context that is not visible in a context-free grammar alone. Ruby syntax is a strong example: lexer state, parser state, newline sensitivity, keywords, and operator contexts all affect tokenization and parsing.

## Lexer And Parser State

Keep context-sensitive decisions close to the component that owns the information. If the lexer decides whether a word is a keyword or an identifier, return distinct tokens. If the parser must influence lexing, pass state explicitly through `%lex-param` and `%parse-param` rather than relying on hidden global state.

```bison
%lex-param {struct parser_state *state}
%parse-param {struct parser_state *state}
```

## Lexical Tie-ins

A lexical tie-in is a parser-driven condition that changes how the lexer tokenizes future input. This can be useful, but it makes grammars harder to reason about. Use clearly named parser state fields and reset them in well-defined actions.

## Token Choices

When syntax depends on context, it is often clearer to split tokens:

```bison
%token IDENTIFIER
%token LABEL
%token KEYWORD_CLASS
```

Different tokens make the parser states and conflict reports easier to read than a single token with large semantic side effects.

## Parameterized Rules For Readability

Parameterized rules help express recurring context patterns without duplicating grammar text:

```bison
arguments:
    delimited('(', separated_list(',', argument), ')')
  ;
```

For CRuby-sized grammars, this keeps repetition out of the grammar while preserving an explicit parse structure after expansion.

## Named References

Use named references when context-sensitive actions would otherwise depend on fragile positional numbers:

```bison
expr[result]:
    expr[left] expr[right] '+'
      { $result = $left + $right; }
  ;
```

This is especially useful after introducing midrule actions or parameterized rules.
