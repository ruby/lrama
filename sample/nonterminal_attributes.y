%{
// Prologue
%}

%union {
  int i;
}

%token <i> k_while
%token <i> k_do
%token <i> k_end

%token <i> tSTRING
%token <i> tIDENTIFIER

%attr DO_ALLOWED

%%

program: stmt(DO_ALLOWED) ;

stmt  : k_while expr(!DO_ALLOWED) k_do stmt k_end
      | expr
      ;

expr  : tSTRING
      | command_call
      ;

command_call: tIDENTIFIER
            | @lhs(DO_ALLOWED) tIDENTIFIER k_do stmt k_end
            ;

%%

