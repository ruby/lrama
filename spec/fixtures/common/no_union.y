/*
 * Test case for parser without %union directive
 */

%{
// Prologue
%}

%token NUMBER
%token PLUS
%token MINUS

%%

program: expr
       ;

expr: NUMBER
    | expr PLUS NUMBER
    | expr MINUS NUMBER
    ;

%%

// Epilogue
