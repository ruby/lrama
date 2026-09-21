# Standard Library

Lrama automatically prepends parameterized rules from `lib/lrama/grammar/stdlib.y` unless the grammar declares `%no-stdlib`.

The standard library defines common optional, sequence, and list patterns.

## Options

`option(X)` accepts either empty input or `X`:

```bison
%rule option(X):
    %empty
  | X
  ;
```

Use it directly:

```bison
maybe_expr:
    option(expr)
  ;
```

or through the suffix:

```bison
maybe_expr:
    expr?
  ;
```

`ioption(X)` is the inline version. It expands the empty-or-`X` alternatives at the use site.

## Sequences

`preceded(opening, X)` matches `opening X` and returns the semantic value of `X`:

```bison
after_colon:
    preceded(':', expr)
  ;
```

`terminated(X, closing)` matches `X closing` and returns the semantic value of `X`:

```bison
expr_before_semicolon:
    terminated(expr, ';')
  ;
```

`delimited(opening, X, closing)` matches `opening X closing` and returns the semantic value of `X`:

```bison
paren_expr:
    delimited('(', expr, ')')
  ;
```

## Lists

`list(X)` accepts zero or more `X` values:

```bison
items:
    list(item)
  ;
```

The suffix form is:

```bison
items:
    item*
  ;
```

`nonempty_list(X)` accepts one or more `X` values:

```bison
items:
    nonempty_list(item)
  ;
```

The suffix form is:

```bison
items:
    item+
  ;
```

## Separated Lists

`separated_nonempty_list(separator, X)` accepts one or more `X` values separated by `separator`:

```bison
members:
    separated_nonempty_list(',', pair)
  ;
```

`separated_list(separator, X)` accepts either empty input or a separated nonempty list:

```bison
arguments:
    separated_list(',', argument)
  ;
```

## Disabling The Standard Library

Use `%no-stdlib` when a grammar must define all parameterized rules itself:

```bison
%no-stdlib
```

After disabling the standard library, suffixes such as `?`, `*`, and `+` still instantiate `option`, `list`, and `nonempty_list`. The grammar must provide compatible definitions if it uses those suffixes.
