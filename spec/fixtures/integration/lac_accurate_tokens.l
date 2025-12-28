%option noinput nounput noyywrap never-interactive bison-bridge bison-locations

%{
#include <stdio.h>
#include <stdlib.h>
#include "lac_accurate_tokens.h"
%}

%%

"if"    { return IF; }
"then"  { return THEN; }
"else"  { return ELSE; }
"while" { return WHILE; }
"do"    { return DO; }

[a-zA-Z_][a-zA-Z0-9_]* {
  (void)yylval;
  (void)yylloc;
  return ID;
}

[0-9]+ {
  (void)yylval;
  (void)yylloc;
  return NUM;
}

[+\-*/] {
  return yytext[0];
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
