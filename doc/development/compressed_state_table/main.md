# Compressed State Table

LR parser generates two large tables, action table and GOTO table.
Action table is a matrix of states and tokens. Each cell of action table indicates next action (shift, reduce, accept and error).
GOTO table is a matrix of states and nonterminal symbols. Each cell of GOTO table indicates next state.

Action table of "parse.y":

|        |EOF| LF|NUM|'+'|'*'|'('|')'|
|--------|--:|--:|--:|--:|--:|--:|--:|
|State  0| r1|   | s1|   |   | s2|   |
|State  1| r3| r3| r3| r3| r3| r3| r3|
|State  2|   |   | s1|   |   | s2|   |
|State  3| s6|   |   |   |   |   |   |
|State  4|   | s7|   | s8| s9|   |   |
|State  5|   |   |   | s8| s9|   |s10|
|State  6|acc|acc|acc|acc|acc|acc|acc|
|State  7| r2| r2| r2| r2| r2| r2| r2|
|State  8|   |   | s1|   |   | s2|   |
|State  9|   |   | s1|   |   | s2|   |
|State 10| r6| r6| r6| r6| r6| r6| r6|
|State 11|   | r4|   | r4| s9|   | r4|
|State 12|   | r5|   | r5| r5|   | r5|

GOTO table of "parse.y":

|        |$accept|program|expr|
|--------|------:|------:|---:|
|State  0|       |     g3|  g4|
|State  1|       |       |    |
|State  2|       |       |  g5|
|State  3|       |       |    |
|State  4|       |       |    |
|State  5|       |       |    |
|State  6|       |       |    |
|State  7|       |       |    |
|State  8|       |       | g11|
|State  9|       |       | g12|
|State 10|       |       |    |
|State 11|       |       |    |
|State 12|       |       |    |


Both action table and GOTO table are sparse. Therefore LR parser generator compresses both tables and creates these tables.

* `yypact` & `yypgoto`
* `yytable`
* `yycheck`
* `yydefact` & `yydefgoto`

## Introduction to major tables

### `yypact` & `yypgoto`

`yypact` specifies offset on `yytable` for the current state.
As an optimization, `yypact` also specifies default reduce action for some states.
Accessing the value by `state`. For example,

```ruby
offset = yypact[state]
```

If the value is `YYPACT_NINF` (Negative INFinity), it means execution of default reduce action.
Otherwise the value is an offset in `yytable`.

`yypgoto` plays the same role as `yypact`.
But `yypgoto` is used for GOTO table.
Then its index is nonterminal symbol id.
Especially `yypgoto` is used when reduce happens.

```ruby
rule_for_reduce = rules[rule_id]

# lhs_id holds LHS nonterminal id of the rule used for reduce.
lhs_id = rule_for_reduce.lhs.id

offset = yypgoto[lhs_id]

# Validate access to yytable
if yycheck[offset + state] == state
  next_state = yytable[offset + state]
end
```

### `yytable`

`yytable` is a mixture of action table and GOTO table.

#### For action table

For action table, `yytable` specifies what actually to do on the current state.

Positive number means shift and specifies next state.
For example, `yytable[yyn] == 1` means shift and next state is State 1.

`YYTABLE_NINF` (Negative INFinity) means syntax error.
For example, `yytable[yyn] == YYTABLE_NINF` means syntax error.

Other negative number and zero mean reducing with the rule whose number is opposite.
For example, `yytable[yyn] == -1` means reduce with Rule 1.

#### For GOTO table

For GOTO table, `yytable` specifies the next state for given LSH nonterminal.

The value is always positive number which means next state id.
It never becomes `YYTABLE_NINF`.

### `yycheck`

`yycheck` validates accesses to `yytable`.

Each line of action table and GOTO table is placed into single array in `yytable`.
Consider the case where action table has only two states.
In this case, if the second array is shifted to the right, they can be merged into one array without conflict.

```ruby
[
  [ 'a', 'b',    ,    , 'e'], # State 0
  [    , 'B', 'C',    , 'E'], # State 1
]

# => Shift the second array to the right

[
  [ 'a', 'b',    ,    , 'e'],      # State 0
       [    , 'B', 'C',    , 'E'], # State 1
]

# => Merge them into single array

yytable = [
    'a', 'b', 'B', 'C', 'e', 'E'
]
```

`yypact` is an array of each state offset.

```ruby
yypact = [
  0, # State 0 is not shifted
  1  # State 1 is shifted one to right
]
```

We can access the value of `state1[2]` by consulting `yypact`.

```ruby
yytable[yypact[1] + 2]
# => yytable[1 + 2]
# => 'C'
```

However this approach doesn't work well when accessing to nil value like `state1[3]`.
Because it tries to access to `state0[4]`.

```ruby
yytable[yypact[1] + 3]
# => yytable[1 + 3]
# => 'e'
```

This is why `yycheck` is needed.
`yycheck` stores valid indexes of the original table.
In the current example:

* 0, 1 and 4 are valid index of State 0
* 1, 2 and 4 are valid index of State 1

`yycheck` stores these indexes with same offset with `yytable`.

```ruby
# yytable
[
  [ 'a', 'b',    ,    , 'e'],      # State 0
       [    , 'B', 'C',    , 'E'], # State 1
]

yytable = [
    'a', 'b', 'B', 'C', 'e', 'E'
]

# yycheck
[
  [   0,   1,    ,    ,   4],      # State 0
       [    ,   1,   2,    ,   4], # State 1
]

yycheck = [
      0,   1,   1,   2,   4,   4
]
```

We can validate accesses to `yytable` by consulting `yycheck`.
`yycheck` stores valid indexes in the original arrays then validation is comparing `yycheck[index_for_yytable]` and `index_for_the_state`.
The access is valid if both values are same.

```ruby
# Validate an access to state1[2]
yycheck[yypact[1] + 2] == 2
# => yycheck[1 + 2] == 2
# => 2 == 2
# => true (valid)

# Validate an access to state1[3]
yycheck[yypact[1] + 3] == 3
# => yycheck[1 + 3] == 3
# => 4 == 3
# => false (invalid)
```

### `yydefact` & `yydefgoto`

`yydefact` stores rule id of default actions for each state.
`0` means syntax error, other number means reduce using Rule N.

```ruby
rule_id = yydefact[state]
# => 0 means syntax error, other number means reduce using Rule whose id is `rule_id`
```

`yydefgoto` stores default GOTOs for each nonterminal.
The number means next state.

```ruby
next_state = yydefgoto[lhs_id]
# => Next state id is `next_state`
```

## Example

Take a look at compressed tables of "parse.y".
See "parse.output" for detailed information of symbols and states.

### `yytable`

Original action table and GOTO table look like:

```ruby
# Action table is a matrix of terminals * states
[
# [   EOF, error, undef,    LF,   NUM,   '+',   '*',   '(',   ')']              (default reduce)
  [      ,      ,      ,      ,    s1,      ,      ,    s2,      ], # State  0  (r1)
  [      ,      ,      ,      ,      ,      ,      ,      ,      ], # State  1  (r3)
  [      ,      ,      ,      ,    s1,      ,      ,    s2,      ], # State  2  ()
  [    s6,      ,      ,      ,      ,      ,      ,      ,      ], # State  3  ()
  [      ,      ,      ,    s7,      ,    s8,    s9,      ,      ], # State  4  ()
  [      ,      ,      ,      ,      ,    s8,    s9,      ,   s10], # State  5  ()
  [      ,      ,      ,      ,      ,      ,      ,      ,      ], # State  6  (accept)
  [      ,      ,      ,      ,      ,      ,      ,      ,      ], # State  7  (r2)
  [      ,      ,      ,      ,    s1,      ,      ,    s2,      ], # State  8  ()
  [      ,      ,      ,      ,    s1,      ,      ,    s2,      ], # State  9  ()
  [      ,      ,      ,      ,      ,      ,      ,      ,      ], # State 10  (r6)
  [      ,      ,      ,      ,      ,      ,    s9,      ,      ], # State 11  (r4)
  [      ,      ,      ,      ,      ,      ,      ,      ,      ], # State 12  (r5)
]

# GOTO table is a matrix of states * nonterminals
[
# [   0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12]    State No (default goto)
  [    ,    ,    ,    ,    ,    ,    ,    ,    ,    ,    ,    ,    ], # $accept  (g0)
  [  g3,    ,    ,    ,    ,    ,    ,    ,    ,    ,    ,    ,    ], # program  (g3)
  [  g4,    ,  g5,    ,    ,    ,    ,    , g11, g12,    ,    ,    ], # expr     (g4)
]

# => Remove default goto

[
# [   0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12]    State No (default goto)
  [    ,    ,    ,    ,    ,    ,    ,    ,    ,    ,    ,    ,    ], # $accept  (g0)
  [    ,    ,    ,    ,    ,    ,    ,    ,    ,    ,    ,    ,    ], # program  (g3)
  [    ,    ,  g5,    ,    ,    ,    ,    , g11, g12,    ,    ,    ], # expr     (g4)
]
```

These are compressed to `yytable` like below.
If offset equals to `YYPACT_NINF`, the line has only default value then the line can be ignored (commented out in this example). 

```ruby
[
# Action table
#                                                                                  (offset, YYPACT_NINF = -4)
                                             [    ,    ,    ,    ,  s1,    ,    ,  s2,    ], # State  0  ( 6)
# [    ,    ,    ,    ,    ,    ,    ,    ,    ],                                            # State  1  (-4)
                                             [    ,    ,    ,    ,  s1,    ,    ,  s2,    ], # State  2  ( 6)
                    [  s6,    ,    ,    ,    ,    ,    ,    ,    ],                          # State  3  ( 1)
          [    ,    ,    ,  s7,    ,  s8,  s9,    ,    ],                                    # State  4  (-1)
                              [    ,    ,    ,    ,    ,  s8,  s9,    , s10],                # State  5  ( 3)
# [    ,    ,    ,    ,    ,    ,    ,    ,    ],                                            # State  6  (-4)
# [    ,    ,    ,    ,    ,    ,    ,    ,    ],                                            # State  7  (-4)
                                             [    ,    ,    ,    ,  s1,    ,    ,  s2,    ], # State  8  ( 6)
                                             [    ,    ,    ,    ,  s1,    ,    ,  s2,    ], # State  9  ( 6)
# [    ,    ,    ,    ,    ,    ,    ,    ,    ],                                            # State 10  (-4)
[    ,    ,    ,    ,    ,    ,  s9,    ,    ],                                              # State 11  (-3)
# [    ,    ,    ,    ,    ,    ,    ,    ,    ],                                            # State 12  (-4)

# GOTO table
# [    ,    ,    ,    ,    ,    ,    ,    ,    ,    ,    ,    ,    ],                        # $accept   (-4)
# [    ,    ,    ,    ,    ,    ,    ,    ,    ,    ,    ,    ,    ],                        # program   (-4)
     [    ,    ,  g5,    ,    ,    ,    ,    , g11, g12,    ,    ,    ],                     # expr      (-2)
]

# => compressed into single array
[    ,    ,    ,  g5,  s6,  s7,  s9,  s8,  s9, g11, g12,  s8,  s9,  s1, s10,    ,  s2,    ]

# => Cut blank cells on head and tail, remove 'g' and 's' prefix, fill blank with 0
#    This is `yytable`
               [   5,   6,   7,   9,   8,   9,  11,  12,   8,   9,   1,  10,   0,   2]
```

`YYTABLE_NINF` is the minimum negative number.
In this case, `0` is the minimum offset number then `YYTABLE_NINF` is `-1`.

### `yycheck`

```ruby
[
# Action table valid indexes
#                                                                                  (offset, YYPACT_NINF = -4)
                                             [    ,    ,    ,    ,   4,    ,    ,   7,    ], # State  0  ( 6)
# [    ,    ,    ,    ,    ,    ,    ,    ,    ],                                            # State  1  (-4)
                                             [    ,    ,    ,    ,   4,    ,    ,   7,    ], # State  2  ( 6)
                    [   0,    ,    ,    ,    ,    ,    ,    ,    ],                          # State  3  ( 1)
          [    ,    ,    ,   3,    ,   5,   6,    ,    ],                                    # State  4  (-1)
                              [    ,    ,    ,    ,    ,   5,   6,    ,   8],                # State  5  ( 3)
# [    ,    ,    ,    ,    ,    ,    ,    ,    ],                                            # State  6  (-4)
# [    ,    ,    ,    ,    ,    ,    ,    ,    ],                                            # State  7  (-4)
                                             [    ,    ,    ,    ,   4,    ,    ,   7,    ], # State  8  ( 6)
                                             [    ,    ,    ,    ,   4,    ,    ,   7,    ], # State  9  ( 6)
# [    ,    ,    ,    ,    ,    ,    ,    ,    ],                                            # State 10  (-4)
[    ,    ,    ,    ,    ,    ,   6,    ,    ],                                              # State 11  (-3)
# [    ,    ,    ,    ,    ,    ,    ,    ,    ],                                            # State 12  (-4)

# GOTO table valid indexes
# [    ,    ,    ,    ,    ,    ,    ,    ,    ,    ,    ,    ,    ],                        # $accept   (-4)
# [    ,    ,    ,    ,    ,    ,    ,    ,    ,    ,    ,    ,    ],                        # program   (-4)
     [    ,    ,   2,    ,    ,    ,    ,    ,   8,   9,    ,    ,    ],                     # expr      (-2)
]

# => compressed into single array
[    ,    ,    ,   2,   0,   3,   6,   5,   6,   8,   9,   5,   6,   4,   8,    ,   7,    ]

# => Cut blank cells on head and tail, fill blank with -1 because no index can be -1 and comparison always fails
#    This is `yycheck`
               [   2,   0,   3,   6,   5,   6,   8,   9,   5,   6,   4,   8,  -1,   7]
```

### `yypact` & `yypgoto`

`yypact` & `yypgoto` are mixture of offset in `yytable` and `YYPACT_NINF` (default reduce action).
Index in `yypact` is state id and index in `yypgoto` is nonterminal symbol id.
`YYPACT_NINF` is the minimum negative number.
In this case, `-3` is the minimum offset number then `YYPACT_NINF` is `-4`.

```ruby
YYPACT_NINF = -4

yypact = [
#  0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12   (State No)
   6,  -4,   6,   1,  -1,   3,  -4,  -4,   6,   6,  -4,  -3,  -4
]

yypgoto = [
#  $accept,   program,      expr
        -4,        -4,        -2
]
```

### `yydefact` & `yydefgoto`

`yydefact` & `yydefgoto` store default value.

`yydefact` specifies rule id of default actions of the state.
Because `0` is reserved for syntax error, Rule id starts with 1.

```
# In "parse.output"
Grammar

    0 $accept: program "end of file"

    1 program: ε
    2        | expr LF

    3 expr: NUM
    4     | expr '+' expr
    5     | expr '*' expr
    6     | '(' expr ')'

# =>

# In `yydefact`
Grammar

    0 Syntax Error

    1 $accept: program "end of file"

    2 program: ε
    3        | expr LF

    4 expr: NUM
    5     | expr '+' expr
    6     | expr '*' expr
    7     | '(' expr ')'
```

For example, default action for state 1 is 4 (`yydefact[1] == 4`).
This means Rule 3 (`3 expr: NUM`) in "parse.output" file.

`yydefgoto` specifies next state id of the nonterminal.

```ruby
yydefact = [
#  0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12   (State No)
   2,   4,   0,   0,   0,   0,   1,   3,   0,   0,   7,   5,   6
]

yydefgoto = [
#  $accept,   program,      expr
         0,         3,         4
]
```

### `yyr1` & `yyr2`

Both of them are tables for rules.
`yyr1` specifies nonterminal symbol id of rule's Left-Hand-Side.
`yyr2` specifies the length of the rule, that is, number of symbols on the rule's Right-Hand-Side.
Index 0 is not used because Rule id starts with 1.

```ruby
yyr1 = [
#        0,       1,       2,       3,    4,    5,    6,    7   (Rule id)
#  no rule, $accept, program, program, expr, expr, expr, expr   (LHS symbol id)
         0,       9,      10,      10,   11,   11,   11,   11
]

yyr2 = [
#  0,   1,   2,   3,   4,   5,   6,   7   (Rule id)
   0,   2,   0,   2,   1,   3,   3,   3
]
```

## How to use tables

See also "parse.rb" which implements LALR parser based on "parse.y" file.

At first, define important constants and arrays:

```ruby
YYNTOKENS = 9

# The last index of yytable and yycheck
# The length of yytable and yycheck are always same
YYLAST    = 13
YYTABLE_NINF = -1
yytable   = [   5,   6,   7,   9,   8,   9,  11,  12,   8,   9,   1,  10,   0,   2]
yycheck   = [   2,   0,   3,   6,   5,   6,   8,   9,   5,   6,   4,   8,  -1,   7]

YYPACT_NINF = -4
yypact    = [   6,  -4,   6,   1,  -1,   3,  -4,  -4,   6,   6,  -4,  -3,  -4]
yypgoto   = [  -4,  -4,  -2]

yydefact  = [   2,   4,   0,   0,   0,   0,   1,   3,   0,   0,   7,   5,   6]
yydefgoto = [   0,   3,   4]

yyr1      = [   0,   9,  10,  10,  11,  11,  11,  11]
yyr2      = [   0,   2,   0,   2,   1,   3,   3,   3]
```

### Determine what to do next

Determine what to do next based on current state (`state`) and next token (`yytoken`).

The first step to decide action is looking up `yypact` table by current state.
If only default reduce exists for the current state, `yypact` returns `YYPACT_NINF`.

```ruby
# Case 1: Only default reduce exists for the state
#
# State 7
#
#     2 program: expr LF •
#
#     $default  reduce using rule 2 (program)

state = 7
yytoken = nil # Do not use yytoken in this case

offset = yypact[state] # -4
if offset == YYPACT_NINF # true
  next_action = :yydefault
  return
end
```

If both shift and default reduce exists for the current state, `yypact` returns offset in `yytable`.
Index is the sum of `offset` and `yytoken`.
Need to check index before access to `yytable` by consulting `yycheck`.
Index can be out of range because blank cells on head and tail are omitted, see how `yycheck` is constructed in the example above.
Therefore need to check an index is not less than 0 and not greater than `YYLAST`.

```ruby
# Case 2: Both shift and default reduce exists for the state
#
# State 11
#
#     4 expr: expr • '+' expr
#     4     | expr '+' expr •  [LF, '+', ')']
#     5     | expr • '*' expr
#
#    '*'  shift, and go to state 9
#
#    $default  reduce using rule 4 (expr)

# Next token is '*' then shift it
state = 11
yytoken = nil

offset = yypact[state] # -3
if offset == YYPACT_NINF # false
  next_action = :yydefault
  break
end

unless yytoken
  yytoken = yylex() # yylex returns 6 ('*')
end

idx = offset + yytoken # 3
if idx < 0 || YYLAST < idx # false
  next_action = :yydefault
  break
end
if yycheck[idx] != yytoken # false
  next_action = :yydefault
  break
end

act = yytable[idx] # 9
if act == YYTABLE_NINF # false
  next_action = :syntax_error
  break
end
if act > 0 # true
  # Shift
  next_action = :yyshift
  break
else
  # Reduce
  next_action = :yyreduce
  break
end
```

### Execute (default) reduce

Once next action is decided to default reduce, need to determine

1. the rule to be applied
2. the next state from GOTO table

Rule id for the default reduce is stored in `yydefact`.
`0` in `yydefact` means syntax error so need to check the value is not `0` before continue the process.

Once rule is determined, the length of the rule can be decided from `yyr2` and the LHS nonterminal can be decided from `yyr1`.

The next state is determined by LHS nonterminal and the state after reduce.
GOTO table is also compressed into `yytable` then the process to decide next state is similar to `yypact`.

1. Look up `yypgoto` by LHS nonterminal. Note `yypact` is indexed by state but `yypgoto` is indexed by nonterminal.
2. Check the value on `yypgoto` is `YYPACT_NINF` is not.
3. Check the index, sum of offset and state, is out of range or not.
4. Check `yycheck` table before access to `yytable`.

Finally push the state to the stack.

```ruby
# State 11
#
#     4 expr: expr • '+' expr
#     4     | expr '+' expr •  [LF, '+', ')']
#     5     | expr • '*' expr
#
#    '*'  shift, and go to state 9
#
#    $default  reduce using rule 4 (expr)

# Input is "1 + 2 + 3 LF" and next token is the second '+'.
# Current state stack is `[0, 4, 8, 11]`.
# What to do next is reduce with default action.
state = 11
yytoken = 5 # '+'

rule = yydefact[state] # 5
if rule == 0 # false
  next_action = :syntax_error
  break
end

rhs_length = yyr2[rule] # 3. Because rule 4 is "expr: expr '+' expr"
lhs_nterm = yyr1[rule]  # 11 (expr)
lhs_nterm_id = lhs_nterm - YYNTOKENS # 11 - 9 = 2

case rule
when 1
  # Execute Rule 1 action
when 2
  # Execute Rule 2 action
#...
when 7
  # Execute Rule 7 action
end

stack.pop(rhs_length) # state stack: `[0, 4, 8, 11]` -> `[0]`
state = stack[-1] # state = 0

offset = yypgoto[lhs_nterm_id] # -2
if offset == YYPACT_NINF # false
  state = yydefgoto[lhs_nterm_id]
else
  idx = offset + state # 0
  if idx < 0 || YYLAST < idx # true
    state = yydefgoto[lhs_nterm_id] # 4
  elsif yycheck[idx] != state
    state = yydefgoto[lhs_nterm_id]
  else
    state = yytable[idx]
  end
end

# yyval = $$, yyloc = @$
push_state(state, yyval, yyloc) # state stack: [0, 4]
```
