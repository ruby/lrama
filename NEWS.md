# NEWS for Lrama

## Lrama 0.7.1 (2025-xx-xx)

### Semantic Predicates

Support semantic predicates to conditionally enable grammar rules based on runtime conditions.
Predicates are evaluated at parse time, similar to ANTLR4's semantic predicates.

```yacc
rule : {expression}? TOKEN { action }
     | TOKEN { action }
     ;
```

The predicate `{expression}?` is evaluated at parse time. If it returns true (non-zero), the alternative is enabled.

Example:

```yacc
widget
    : {new_syntax}? WIDGET ID NEW_ARG
      { printf("New syntax\n"); }
    | {!new_syntax}? WIDGET ID OLD_ARG
      { printf("Old syntax\n"); }
    ;
```

Predicates are compiled into static functions in the generated parser.
Leading predicates (at the start of a rule) affect prediction, while trailing predicates act as validation.

### Syntax Diagrams

Lrama provides an API for generating HTML syntax diagrams. These visual diagrams are highly useful as grammar development tools and can also serve as a form of automatic self-documentation.

![Syntax Diagrams](https://github.com/user-attachments/assets/5d9bca77-93fd-4416-bc24-9a0f70693a22)

If you use syntax diagrams, you add `--diagram` option.

```console
$ exe/lrama --diagram sample.y
```

### Support `--profile` option

You can profile parser generation process without modification for Lrama source code.
Currently `--profile=call-stack` and `--profile=memory` are supported.

```console
$ exe/lrama --profile=call-stack sample/calc.y
```

Then "tmp/stackprof-cpu-myapp.dump" is generated.

https://github.com/ruby/lrama/pull/525

## Lrama 0.7.0 (2025-01-21)

### [EXPERIMENTAL] Support the generation of the IELR(1) parser described in this paper

Support the generation of the IELR(1) parser described in this paper.
https://www.sciencedirect.com/science/article/pii/S0167642309001191

If you use IELR(1) parser, you can write the following directive in your grammar file.

```yacc
%define lr.type ielr
```

But, currently IELR(1) parser is experimental feature. If you find any bugs, please report it to us. Thank you.

### Support `-t` option as same as `--debug` option

Support to `-t` option as same as `--debug` option.
These options align with Bison behavior. So same as `--debug` option.

### Trace only explicit rules

Support to trace only explicit rules.
If you use `--trace=rules` option, it shows include mid-rule actions. If you want to show only explicit rules, you can use `--trace=only-explicit-rules` option.

Example:

```yacc
%{
%}
%union {
    int i;
}
%token <i> number
%type <i> program
%%
program         : number { printf("%d", $1); } number { $$ = $1 + $3; }
                ;
%%
```

Result of `--trace=rules`:

```console
$ exe/lrama --trace=rules sample.y
Grammar rules:
$accept -> program YYEOF
$@1 -> ε
program -> number $@1 number
```

Result of `--trace=only-explicit-rules`:

```console
$ exe/lrama --trace=explicit-rules sample.y
Grammar rules:
$accept -> program YYEOF
program -> number number
```

## Lrama 0.6.11 (2024-12-23)

### Add support for %type declarations using %nterm in Nonterminal Symbols

Allow to use `%nterm` in Nonterminal Symbols for `%type` declarations.

```yacc
%nterm <type> nonterminal…
```

This directive is also supported for compatibility with Bison, and only non-terminal symbols are allowed. In other words, definitions like the following will result in an error:

```yacc
%{
// Prologue
%}

%token EOI 0 "EOI"
%nterm EOI

%%

program: /* empty */
        ;
```

It show an error message like the following:

```command
❯ exe/lrama nterm.y
nterm.y:6:7: symbol EOI redeclared as a nonterminal
%nterm EOI
       ^^^
```

## Lrama 0.6.10 (2024-09-11)

### Aliased Named References for actions of RHS in Parameterizing rules

Allow to use aliased named references for actions of RHS in Parameterizing rules.

```yacc
%rule sum(X, Y): X[summand] '+' Y[addend] { $$ = $summand + $addend }
               ;
```

https://github.com/ruby/lrama/pull/410


### Named References for actions of RHS in Parameterizing rules caller side

Allow to use named references for actions of RHS in Parameterizing rules caller side.

```yacc
opt_nl: '\n'?[nl] <str> { $$ = $nl; }
      ;
```

https://github.com/ruby/lrama/pull/414

### Widen the definable position of Parameterizing rules

Allow to define Parameterizing rules in the middle of the grammar.

```yacc
%rule defined_option(X): /* empty */
                       | X
                       ;

%%

program         : defined_option(number) <i>
                | defined_list(number) <i>
                ;

%rule defined_list(X): /* empty */  /* <--- here */
                     | defined_list(X) number
                     ;
```

https://github.com/ruby/lrama/pull/420

### Report unused terminal symbols

Support to report unused terminal symbols.
Run `exe/lrama --report=terms` to show unused terminal symbols.

```console
$ exe/lrama --report=terms sample/calc.y
 11 Unused Terms
     0 YYerror
     1 YYUNDEF
     2 '\\\\'
     3 '\\13'
     4 keyword_class2
     5 tNUMBER
     6 tPLUS
     7 tMINUS
     8 tEQ
     9 tEQEQ
    10 '>'
```
https://github.com/ruby/lrama/pull/439

### Report unused rules

Support to report unused rules.
Run `exe/lrama --report=rules` to show unused rules.

```console
$ exe/lrama --report=rules sample/calc.y
  3 Unused Rules
     0 unused_option
     1 unused_list
     2 unused_nonempty_list
```

https://github.com/ruby/lrama/pull/441

### Ensure compatibility with Bison for `%locations` directive

Support `%locations` directive to ensure compatibility with Bison.
Change to `%locations` directive not set by default.

https://github.com/ruby/lrama/pull/446

### Diagnostics report for parameterized rules redefine

Support to warning redefined parameterized rules.
Run `exe/lrama -W` or  `exe/lrama --warnings` to show redefined parameterized rules.

```console
$ exe/lrama -W sample/calc.y
parameterized rule redefined: redefined_method(X)
parameterized rule redefined: redefined_method(X)
```

https://github.com/ruby/lrama/pull/448

### Support `-v` and `--verbose` option

Support to `-v` and `--verbose` option.
These options align with Bison behavior. So same as '--report=state' option.

https://github.com/ruby/lrama/pull/457

## Lrama 0.6.9 (2024-05-02)

### Callee side tag specification of Parameterizing rules

Allow to specify tag on callee side of Parameterizing rules.

```yacc
%union {
    int i;
}

%rule with_tag(X) <i>: X { $$ = $1; }
                     ;
```

### Named References for actions of RHS in Parameterizing rules

Allow to use named references for actions of RHS in Parameterizing rules.

```yacc
%rule option(number): /* empty */
                    | number { $$ = $number; }
                    ;
```

## Lrama 0.6.8 (2024-04-29)

### Nested Parameterizing rules with tag

Allow to nested Parameterizing rules with tag.

```yacc
%union {
    int i;
}

%rule nested_nested_option(X): /* empty */
                              | X
                              ;

%rule nested_option(X): /* empty */
                       | nested_nested_option(X) <i>
                       ;

%rule option(Y): /* empty */
               | nested_option(Y) <i>
               ;
```

## Lrama 0.6.7 (2024-04-28)

### RHS of user defined Parameterizing rules contains `'symbol'?`, `'symbol'+` and `'symbol'*`.

User can use `'symbol'?`, `'symbol'+` and `'symbol'*` in RHS of user defined Parameterizing rules.

```
%rule with_word_seps(X): /* empty */
                   | X ' '+
                   ;
```

## Lrama 0.6.6 (2024-04-27)

### Trace actions

Support trace actions for debugging.
Run `exe/lrama --trace=actions` to show grammar rules with actions.

```console
$ exe/lrama --trace=actions sample/calc.y
Grammar rules with actions:
$accept -> list, YYEOF {}
list -> ε {}
list -> list, LF {}
list -> list, expr, LF { printf("=> %d\n", $2); }
expr -> NUM {}
expr -> expr, '+', expr { $$ = $1  +  $3; }
expr -> expr, '-', expr { $$ = $1  -  $3; }
expr -> expr, '*', expr { $$ = $1  *  $3; }
expr -> expr, '/', expr { $$ = $1  /  $3; }
expr -> '(', expr, ')' { $$ = $2; }
```

### Inlining

Support inlining for rules.
The `%inline` directive causes all references to symbols to be replaced with its definition.

```yacc
%rule %inline op: PLUS { + }
                | TIMES { * }
                ;

%%

expr : number { $$ = $1; }
     | expr op expr { $$ = $1 $2 $3; }
     ;
```

as same as

```yacc
expr : number { $$ = $1; }
     | expr '+' expr { $$ = $1 + $3; }
     | expr '*' expr { $$ = $1 * $3; }
     ;
```

## Lrama 0.6.5 (2024-03-25)

### Typed Midrule Actions

User can specify the type of mid-rule action by tag (`<bar>`) instead of specifying it with in an action.

```yacc
primary: k_case expr_value terms?
           {
               $<val>$ = p->case_labels;
               p->case_labels = Qnil;
           }
         case_body
         k_end
           {
             ...
           }
```

can be written as

```yacc
primary: k_case expr_value terms?
           {
               $$ = p->case_labels;
               p->case_labels = Qnil;
           }<val>
         case_body
         k_end
           {
             ...
           }
```

`%destructor` for midrule action is invoked only when tag is specified by Typed Midrule Actions.

Difference from Bison's Typed Midrule Actions is that tag is postposed in Lrama however it's preposed in Bison.

Bison supports this feature from 3.1.

## Lrama 0.6.4 (2024-03-22)

### Parameterizing rules (preceded, terminated, delimited)

Support `preceded`, `terminated` and `delimited` rules.

```text
program: preceded(opening, X)

// Expanded to

program: preceded_opening_X
preceded_opening_X: opening X
```

```
program: terminated(X, closing)

// Expanded to

program: terminated_X_closing
terminated_X_closing: X closing
```

```
program: delimited(opening, X, closing)

// Expanded to

program: delimited_opening_X_closing
delimited_opening_X_closing: opening X closing
```

https://github.com/ruby/lrama/pull/382

### Support `%destructor` declaration

User can set codes for freeing semantic value resources by using `%destructor`.
In general, these resources are freed by actions or after parsing.
However, if syntax error happens in parsing, these codes may not be executed.
Codes associated to `%destructor` are executed when semantic value is popped from the stack by an error.

```yacc
%token <val1> NUM
%type <val2> expr2
%type <val3> expr

%destructor {
    printf("destructor for val1: %d\n", $$);
} <val1> // printer for TAG

%destructor {
    printf("destructor for val2: %d\n", $$);
} <val2>

%destructor {
    printf("destructor for expr: %d\n", $$);
} expr // printer for symbol
```

Bison supports this feature from 1.75b.

https://github.com/ruby/lrama/pull/385

## Lrama 0.6.3 (2024-02-15)

### Bring Your Own Stack

Provide functionalities for Bring Your Own Stack.

Ruby’s Ripper library requires their own semantic value stack to manage Ruby Objects returned by user defined callback method. Currently Ripper uses semantic value stack (`yyvsa`) which is used by parser to manage Node. This hack introduces some limitation on Ripper. For example, Ripper can not execute semantic analysis depending on Node structure.

Lrama introduces two features to support another semantic value stack by parser generator users.

1. Callback entry points

User can emulate semantic value stack by these callbacks.
Lrama provides these five callbacks. Registered functions are called when each event happens. For example %after-shift function is called when shift happens on original semantic value stack.

* `%after-shift` function_name
* `%before-reduce` function_name
* `%after-reduce` function_name
* `%after-shift-error-token` function_name
* `%after-pop-stack` function_name

2. `$:n` variable to access index of each grammar symbols

User also needs to access semantic value of their stack in grammar action. `$:n` provides the way to access to it. `$:n` is translated to the minus index from the top of the stack.
For example

```yacc
primary: k_if expr_value then compstmt if_tail k_end
          {
          /*% ripper: if!($:2, $:4, $:5) %*/
          /* $:2 = -5, $:4 = -3, $:5 = -2. */
          }
```

https://github.com/ruby/lrama/pull/367

## Lrama 0.6.2 (2024-01-27)

### %no-stdlib directive

If `%no-stdlib` directive is set, Lrama doesn't load Lrama standard library for
parameterized rules, stdlib.y.

https://github.com/ruby/lrama/pull/344

## Lrama 0.6.1 (2024-01-13)

### Nested Parameterizing rules

Allow to pass an instantiated rule to other Parameterizing rules.

```yacc
%rule constant(X) : X
                  ;

%rule option(Y) : /* empty */
                | Y
                ;

%%

program         : option(constant(number)) // Nested rule
                ;
%%
```

Allow to use nested Parameterizing rules when define Parameterizing rules.

```yacc
%rule option(x) : /* empty */
                | X
                ;

%rule double(Y) : Y Y
                ;

%rule double_opt(A) : option(double(A)) // Nested rule
                    ;

%%

program         : double_opt(number)
                ;

%%
```

https://github.com/ruby/lrama/pull/337

## Lrama 0.6.0 (2023-12-25)

### User defined Parameterizing rules

Allow to define Parameterizing rule by `%rule` directive.

```yacc
%rule pair(X, Y): X Y { $$ = $1 + $2; }
                ;

%%

program: stmt
       ;

stmt: pair(ODD, EVEN) <num>
    | pair(EVEN, ODD) <num>
    ;
```

https://github.com/ruby/lrama/pull/285

## Lrama 0.5.11 (2023-12-02)

### Type specification of Parameterizing rules

Allow to specify type of rules by specifying tag, `<i>` in below example.
Tag is post-modification style.

```yacc
%union {
    int i;
}

%%

program         : option(number) <i>
                | number_alias? <i>
                ;
```

https://github.com/ruby/lrama/pull/272


## Lrama 0.5.10 (2023-11-18)

### Parameterizing rules (option, nonempty_list, list)

Support function call style Parameterizing rules for `option`, `nonempty_list` and `list`.

https://github.com/ruby/lrama/pull/197

### Parameterizing rules (separated_list)

Support `separated_list` and `separated_nonempty_list` Parameterizing rules.

```text
program: separated_list(',', number)

// Expanded to

program: separated_list_number
separated_list_number: ε
separated_list_number: separated_nonempty_list_number
separated_nonempty_list_number: number
separated_nonempty_list_number: separated_nonempty_list_number ',' number
```

```
program: separated_nonempty_list(',', number)

// Expanded to

program: separated_nonempty_list_number
separated_nonempty_list_number: number
separated_nonempty_list_number: separated_nonempty_list_number ',' number
```

https://github.com/ruby/lrama/pull/204

## Lrama 0.5.9 (2023-11-05)

### Parameterizing rules (suffix)

Parameterizing rules are template of rules.
It's very common pattern to write "list" grammar rule like:

```yacc
opt_args: /* none */
        | args
        ;

args: arg
    | args arg
```

Lrama supports these suffixes:

* `?`: option
* `+`: nonempty list
* `*`: list

Idea of Parameterizing rules comes from Menhir LR(1) parser generator (https://gallium.inria.fr/~fpottier/menhir/manual.html#sec32).

https://github.com/ruby/lrama/pull/181

## Lrama 0.5.7 (2023-10-23)

### Racc parser

Replace Lrama's parser from handwritten parser to LR parser generated by Racc.
Lrama uses `--embedded` option to generate LR parser because Racc is changed from default gem to bundled gem by Ruby 3.3 (https://github.com/ruby/lrama/pull/132).

https://github.com/ruby/lrama/pull/62

## Lrama 0.5.4 (2023-08-17)

### Runtime configuration for error recovery

Make error recovery function configurable on runtime by two new macros.

* `YYMAXREPAIR`: Expected to return max length of repair operations. `%parse-param` is passed to this function.
* `YYERROR_RECOVERY_ENABLED`: Expected to return bool value to determine error recovery is enabled or not. `%parse-param` is passed to this function.

https://github.com/ruby/lrama/pull/74

## Lrama 0.5.3 (2023-08-05)

### Error Recovery

Support token insert base Error Recovery.
`-e` option is needed to generate parser with error recovery functions.

https://github.com/ruby/lrama/pull/44

## Lrama 0.5.2 (2023-06-14)

### Named References

Instead of positional references like `$1` or `$$`,
named references allow to access to symbol by name.

```yacc
primary: k_class cpath superclass bodystmt k_end
           {
             $primary = new_class($cpath, $bodystmt, $superclass);
           }
```

Alias name can be declared.

```yacc
expr[result]: expr[ex-left] '+' expr[ex.right]
                {
                  $result = $[ex-left] + $[ex.right];
                }
```

Bison supports this feature from 2.5.

### Add parse params to some macros and functions

`%parse-param` are added to these macros and functions to remove ytab.sed hack from Ruby.

* `YY_LOCATION_PRINT`
* `YY_SYMBOL_PRINT`
* `yy_stack_print`
* `YY_STACK_PRINT`
* `YY_REDUCE_PRINT`
* `yysyntax_error`

https://github.com/ruby/lrama/pull/40

See also: https://github.com/ruby/ruby/pull/7807

## Lrama 0.5.0 (2023-05-17)

### stdin mode

When `-` is given as grammar file name, reads the grammar source from STDIN, and takes the next argument as the input file name. This mode helps pre-process a grammar source.

https://github.com/ruby/lrama/pull/8

## Lrama 0.4.0 (2023-05-13)

This is the first version migrated to Ruby.
This version generates "parse.c" compatible with Bison 3.8.2.
