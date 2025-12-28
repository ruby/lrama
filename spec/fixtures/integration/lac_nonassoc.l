%option noinput nounput noyywrap never-interactive bison-bridge bison-locations

%{
#include <stdio.h>
#include <stdlib.h>
#include "lac_nonassoc.h"
%}

%%

[0-9]+ {
  (void)yylval;
  (void)yylloc;
  return NUMBER;
}

"<" {
  return '<';
}

[\n|\r\n] {
  return(YYEOF);
}

[[:space:]] {}

<<EOF>> {
  return(YYEOF);
}

. {
  fprintf(stderr, "Illegal character '%s'\n", yytext);
  return(YYEOF);
}

%%
