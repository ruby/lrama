/*
 * This is comment for this file.
 */

%{
// Prologue
%}

%token tNUMBER

%%

program: stmt ;

stmt: expr opt_semicolon
    | opt_expr opt_colon
    | /* empty */
    ;

expr: tNUMBER;

opt_expr: /* empty */
        | expr
        ;

opt_semicolon: /* empty */
             | ';'
             ;

opt_colon: %empty
         | '.'
         ;

%%

// Epilogue
