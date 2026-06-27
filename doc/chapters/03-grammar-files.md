# Grammar Files

An Lrama grammar file has the same broad shape as a Bison grammar file:

```bison
%{
/* prologue */
%}

/* declarations */

%%

/* grammar rules */

%%

/* epilogue */
```

The prologue and epilogue are optional. The grammar rules section is required.

## Prologue

Code between `%{` and `%}` is copied to the generated parser before the parser implementation. Use it for C includes, forward declarations, and macros needed by the generated code.

`%require "VERSION"` is accepted by the grammar parser. Current warning code reports that `%require` is valid syntax but does not enforce a version requirement.

## Declarations

Common declarations include:

```bison
%expect 0
%define parse.error verbose
%union { int val; }
%token <val> NUM
%type <val> expr
%left '+' '-'
%left '*' '/'
%start program
%locations
```

Lrama recognizes parser options such as `%define`, `%lex-param`, `%parse-param`, `%code`, `%initial-action`, `%no-stdlib`, and `%locations`.

It recognizes grammar declarations such as `%token`, `%type`, `%nterm`, `%union`, `%destructor`, `%printer`, `%error-token`, precedence directives, `%start`, `%rule`, `%rule %inline`, and the Lrama-specific hook declarations.

See [Directive Reference](../appendices/a-directive-reference.md) for the complete table.

## Rules

Rules are written after the first `%%`:

```bison
program:
    stmt_list
  ;

stmt_list:
    %empty
  | stmt_list stmt
  ;
```

Use `%empty` for an explicit empty alternative. A C action can appear at the end of an alternative or as a midrule action.

## Semantic And Location References

Actions can use positional references:

```bison
expr:
    expr '+' expr { $$ = $1 + $3; }
  ;
```

They can also use named references:

```bison
expr[result]:
    expr[left] expr[right] '+'
      { $result = $left + $right; }
  ;
```

Use bracketed names when the reference contains characters such as `.` or `-`:

```bison
expr:
    expr[ex-left] expr[ex.right] '+'
      { $$ = $[ex-left] + $[ex.right]; }
  ;
```

Location references use `@`:

```bison
line:
    expr { print_location(&@expr); }
  ;
```

Lrama also supports `$:n` index references used by CRuby-oriented hooks and diagnostics. `$:$` is not supported.

## Parameterized Rules

Lrama can define and instantiate parameterized rules:

```bison
%rule delimited(opening, X, closing):
    opening X closing { $$ = $2; }
  ;

primary:
    delimited('(', expr, ')')
  ;
```

The standard library is prepended automatically unless `%no-stdlib` is declared. It provides helpers such as `option(X)`, `list(X)`, and `separated_nonempty_list(separator, X)`.

The suffixes `?`, `*`, and `+` instantiate standard rules:

```bison
maybe_expr: expr?;
many_exprs: expr*;
one_or_more_exprs: expr+;
```

## Inline Rules

`%rule %inline` defines a parameterized or non-parameterized rule that is expanded at each use site:

```bison
%rule %inline op:
    '+' { + }
  | '-' { - }
  ;
```

Inlining is useful when a helper rule improves readability but would otherwise create a state or conflict shape that differs from the desired grammar.

## Lrama Hooks

The current grammar parser recognizes these hook declarations:

```bison
%after-shift callback_name
%before-reduce callback_name
%after-reduce callback_name
%after-shift-error-token callback_name
%after-pop-stack callback_name
```

The fixture `spec/fixtures/integration/after_shift.y` shows expected callback signatures and how hooks observe parser stack events.

## Unsupported Or Partial Features

Do not assume every Bison declaration is available. For example, GLR parsers, push parsers, LAC, and non-C backends are not currently provided by Lrama. Some directives, such as `%require` and `%param`, are accepted by the grammar parser but have limited or no current code generation effect. Prefer source-backed behavior over Bison manual expectations when documenting or relying on a feature.
