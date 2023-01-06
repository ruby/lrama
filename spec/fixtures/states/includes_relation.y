/*
 * This is comment for this file.
 * This grammar comes from https://dl.acm.org/doi/pdf/10.1145/69622.357187 (P. 628)
 */

%{
// Prologue
%}

%token a b c d

%%

program: A ;

A: b B
 | a
 ;

B: c C;

C: d A;

%%

// Epilogue
