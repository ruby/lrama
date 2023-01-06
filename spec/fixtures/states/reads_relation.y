/*
 * This is comment for this file.
 * This grammar comes from https://dl.acm.org/doi/pdf/10.1145/69622.357187 (P. 629)
 */

%{
// Prologue
%}

%token a

%%

program: A ;

A: B C D A
 | a
 ;

B: /* empty */ ;

C: /* empty */ ;

D: /* empty */ ;

%%

// Epilogue
