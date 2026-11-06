/* IELR differential generator seed 108. */
%define lr.type ielr
%token t0 t1 t2 t3 t4
%nonassoc t0
%nonassoc t2
%nonassoc t1
%left t4
%nonassoc t3
%%
start: n0;
n0: t1 | n2 n5 %prec t1 | t4 n2;
n1: t0 | ;
n2: t0 | t2 n4 | t3 n5;
n3: t4 | ;
n4: t0 | n5 n5 | t4;
n5: t3 | t4 %prec t1 | ;
n6: t2 | t3 t2;
