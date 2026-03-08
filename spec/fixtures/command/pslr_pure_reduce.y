%define lr.type pslr

%token-pattern RSHIFT />>/
%token-pattern RANGLE />/
%token-pattern ID /[a-z]+/

%lex-prec RANGLE -s RSHIFT

%%

program
  : templ
  | rshift_expr
  ;

templ
  : a RANGLE
  ;

rshift_expr
  : a RSHIFT ID
  ;

a
  : ID
  ;
