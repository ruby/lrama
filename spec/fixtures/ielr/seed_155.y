/* IELR differential generator seed 155. */
%define lr.type ielr
%token t0 t1 t2 t3 t4
%left t0
%right t3
%left t2
%nonassoc t1
%right t4
%%
start: n0;
n0: t3 | n5 n5;
n1: t0 | n2 n5;
n2: t0 | ;
n3: t0 | n6 | %prec t2;
n4: t4 | t2;
n5: t1 | n6 t3;
n6: t1 | t3 %prec t3 | t2;
