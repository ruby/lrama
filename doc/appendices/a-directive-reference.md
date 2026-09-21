# Directive Reference

This table is based on the current grammar accepted by `parser.y`. "Recognized" means the parser accepts the syntax, but the current implementation has limited or no generated-code effect.

| Directive | Syntax | Status | Notes |
| --- | --- | --- | --- |
| Prologue | `%{ ... %}` | Supported | Copied into generated C output. |
| `%require` | `%require "VERSION"` | Recognized | Accepted as grammar syntax. With warnings enabled, Lrama reports that it currently does nothing. |
| `%expect` | `%expect INTEGER` | Supported | Sets the expected conflict count. |
| `%define` | `%define name value`, `%define name { value }` | Supported | Stored in grammar definitions. `lr.type=ielr` enables IELR computation; `parse.trace` enables parser debug parsing of the grammar file. |
| `%param` | `%param {type name}` | Recognized | Accepted by `parser.y`; prefer `%lex-param` and `%parse-param` for generated parser parameters. |
| `%lex-param` | `%lex-param {type name}` | Supported | Adds a parameter passed to `yylex`. |
| `%parse-param` | `%parse-param {type name}` | Supported | Adds a parameter passed to `yyparse` and `yyerror`. |
| `%code` | `%code ID { ... }` | Supported | Stores named code blocks for skeleton output. Common examples use `%code provides`. |
| `%initial-action` | `%initial-action { ... }` | Supported | Stores initialization code for generated parser use. |
| `%no-stdlib` | `%no-stdlib` | Supported | Prevents automatic loading of `lib/lrama/grammar/stdlib.y`. |
| `%locations` | `%locations` | Supported | Enables location support. Location references also enable locations during grammar preparation. |
| `%union` | `%union { ... }` | Supported | Defines `YYSTYPE` union members. |
| `%destructor` | `%destructor { ... } symbols-or-tags` | Supported | Associates cleanup code with symbols or tags. |
| `%printer` | `%printer { ... } symbols-or-tags` | Supported | Associates debug printing code with symbols or tags. |
| `%error-token` | `%error-token { ... } symbols-or-tags` | Supported | Associates error-token code with symbols or tags. |
| `%after-shift` | `%after-shift identifier` | Supported | Lrama-specific generated parser hook. |
| `%before-reduce` | `%before-reduce identifier` | Supported | Lrama-specific generated parser hook. |
| `%after-reduce` | `%after-reduce identifier` | Supported | Lrama-specific generated parser hook. |
| `%after-shift-error-token` | `%after-shift-error-token identifier` | Supported | Lrama-specific generated parser hook. |
| `%after-pop-stack` | `%after-pop-stack identifier` | Supported | Lrama-specific generated parser hook. |
| `%token` | `%token [<tag>] NAME [NUMBER] ["alias"]` | Supported | Declares terminals. Multiple tag groups are accepted. |
| `%type` | `%type <tag> symbol...` | Supported | Assigns semantic value tags. |
| `%nterm` | `%nterm <tag> symbol...` | Supported | Assigns tags to nonterminals and errors if a terminal is redeclared as a nonterminal. |
| `%left` | `%left [<tag>] token...` | Supported | Declares left associativity and precedence. |
| `%right` | `%right [<tag>] token...` | Supported | Declares right associativity and precedence. |
| `%nonassoc` | `%nonassoc [<tag>] token...` | Supported | Declares nonassociativity and precedence. |
| `%precedence` | `%precedence [<tag>] token...` | Supported | Declares precedence without associativity. |
| `%start` | `%start nonterminal` | Supported | Sets the start nonterminal. Multiple `%start` declarations are an error in Lrama. |
| `%rule` | `%rule name(args): alternatives ;` | Supported | Defines a parameterized rule. |
| `%rule %inline` | `%rule %inline name(args): alternatives ;` | Supported | Defines a parameterized rule expanded at use sites. |
| Grammar separator | `%%` | Supported | Separates declarations, rules, and optional epilogue. |
| `%empty` | `%empty` | Supported | Marks an empty alternative explicitly. |
| `%prec` | `%prec symbol` | Supported | Overrides the rule precedence. Multiple `%prec` directives in one rule are an error. |

## Rule References

Semantic value references:

| Form | Meaning |
| --- | --- |
| `$$` | Value of the left-hand side. |
| `$1`, `$2` | Positional right-hand side values. |
| `$name` | Named reference. |
| `$[name.with-punctuation]` | Bracketed named reference. |
| `$<tag>1`, `$<tag>$` | Explicit tag override. |

Location references:

| Form | Meaning |
| --- | --- |
| `@$` | Location of the left-hand side. |
| `@1`, `@2` | Positional right-hand side locations. |
| `@name` | Named location reference. |
| `@[name.with-punctuation]` | Bracketed named location reference. |

Index references:

| Form | Meaning |
| --- | --- |
| `$:1`, `$:name` | Parser stack index reference used by Lrama-generated code. |
| `$:$` | Parsed as a reference form but not supported by code generation. |

## Parameterized Rule Forms

| Form | Expansion target |
| --- | --- |
| `symbol?` | `option(symbol)` |
| `symbol*` | `list(symbol)` |
| `symbol+` | `nonempty_list(symbol)` |
| `name(arg1, arg2)` | User-defined or standard-library parameterized rule. |
