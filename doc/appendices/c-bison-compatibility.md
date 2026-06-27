# Bison Compatibility

Lrama is Bison-style, not Bison-complete. This matrix records practical compatibility for the current repository.

| Bison feature or area | Lrama status | Notes |
| --- | --- | --- |
| `.y` grammar layout | Supported | Prologue, declarations, rules, and epilogue are supported. |
| C LALR(1) parser generation | Supported | This is Lrama's main output mode. |
| `%token`, `%type`, `%nterm`, `%union` | Supported | See the directive reference for syntax details. |
| Precedence and associativity | Supported | `%left`, `%right`, `%nonassoc`, `%precedence`, and `%prec` are accepted. |
| `%start` | Supported with difference | Multiple `%start` declarations are an error in Lrama. |
| Semantic actions | Supported | Includes positional, named, bracketed named, and explicit-tag references. |
| Location references | Supported | `@` references enable location support during grammar preparation. |
| `%destructor` and `%printer` | Supported | Used by generated C output and debug support. |
| `%require` | Recognized only | Accepted, but warnings state that it currently has no effect. |
| `%param` | Recognized with limited effect | Use `%lex-param` and `%parse-param` for generated parser parameters. |
| `%lex-param`, `%parse-param` | Supported | Parameters are passed to generated parser functions. |
| IELR | Supported when requested | Use `%define lr.type ielr`; covered by integration fixtures. |
| GLR | Not currently provided | No GLR skeleton or parser mode is provided. |
| Push parser | Not currently provided | The generated C skeleton is pull-parser oriented. |
| LAC | Not currently provided | The README records the LAC branch as disabled in the compatibility assumptions. |
| C++/D/Java backends | Not currently provided | Current repository templates target C output. |
| Parameterized rules | Lrama extension | `%rule`, suffixes, and `stdlib.y` helpers are Lrama grammar features. |
| `%inline` parameterized rules | Lrama extension | Rules are expanded before parser states are finalized. |
| Syntax diagrams | Lrama extension | Generated with `--diagram`. |
| Error-tolerant parser support | Lrama extension | Enabled with `-e` and related grammar support. |
| Bison manual text | Not reused | Documentation should explain Lrama behavior in original wording. |

## Compatibility Guidance

When porting a Bison grammar:

1. Generate reports with both tools if possible.
2. Check unsupported directives before changing parser behavior.
3. Compile and run generated parser tests.
4. Confirm conflict counts with `%expect`.
5. Avoid documenting future or unmerged behavior as supported.

## README Compatibility Assumptions

The README records several Bison template compatibility assumptions:

- `b4_locations_if` is always true.
- `b4_pure_if` is always true.
- `b4_pull_if` is always false.
- `b4_lac_if` is always false.

These are implementation compatibility notes for Lrama's Bison-style template layer. They should not be read as a promise that every Bison command-line option or skeleton branch exists in Lrama.
