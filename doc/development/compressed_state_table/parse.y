%union {
    int val;
}
%token LF
%token <val> NUM
%type <val> expr
%left '+'
%left '*'

%%

program : /* empty */
        | expr LF { printf("=> %d\n", $1); }
        ;

expr    : NUM
        | expr '+' expr { $$ = $1 + $3; }
        | expr '*' expr { $$ = $1 * $3; }
        | '(' expr ')'  { $$ = $2; }
        ;

%%
