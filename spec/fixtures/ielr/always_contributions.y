%define lr.type ielr
%%
start: expr;
expr: pair tail;
pair: 'a' 'a';
tail: 'a' list | expr 'b';
list: tail list | %empty;
