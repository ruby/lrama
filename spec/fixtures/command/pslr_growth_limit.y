%define lr.type pslr

%token-pattern P /p/
%token-pattern Q /q/
%token-pattern X /x/
%token-pattern IF /if/
%token-pattern ID /[a-z]+/

%lex-prec ID <~ IF

%%

program
  : kw_context
  | id_context
  ;

kw_context
  : P shared IF
  ;

id_context
  : Q shared ID
  ;

shared
  : n1
  ;

n1
  : n2
  ;

n2
  : X
  ;
