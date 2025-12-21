/*
 * Test case for parser without %union but with typed tokens
 */

%{
// Prologue
%}

%token <val> NUMBER
%token PLUS
%token MINUS

%type <val> expr

%%

program: expr
       ;

expr: NUMBER
    | expr PLUS NUMBER
    | expr MINUS NUMBER
    ;

%%

// Epilogue
