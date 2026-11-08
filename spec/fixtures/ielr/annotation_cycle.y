%define lr.type ielr
%expect 1
%%
start: expr;
expr: 'a' | expr expr expr;
