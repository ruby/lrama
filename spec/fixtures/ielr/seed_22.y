/* IELR differential generator seed 22. */
%define lr.type ielr
%token t0 t1 t2 t3 t4
%nonassoc t1
%nonassoc t2
%precedence t3
%left t0
%left t4
%%
start: n0;
n0: t4 | n4 n6 | n5 n4 %prec t3;
n1: t4 | t2;
n2: t1 | n5 n5 | n5 t4;
n3: t4 | t1 | t1 t4 %prec t3;
n4: t1 | t4 | t1 %prec t1;
n5: t4 |  | t4 %prec t2;
n6: t3 | t4 t4 %prec t1 | t0;
