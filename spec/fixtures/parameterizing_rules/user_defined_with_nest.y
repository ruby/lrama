/*
 * This is comment for this file.
 */

%{
// Prologue
static int yylex(YYSTYPE *val, YYLTYPE *loc);
static int yyerror(YYLTYPE *loc, const char *str);
%}

%union {
    int i;
    char* s;
}

%token <i> number
%token <s> string

%rule nested_nested_option(X): /* empty */
                              | X
                              ;

%rule nested_option(X): /* empty */
                       | nested_nested_option(X)
                       ;

%rule option(Y): /* empty */
               | nested_option(Y)
               ;

%rule nested_multi_option(X): /* empty */
                              | X
                              ;

%rule multi_option(X, Y): /* empty */
                        | nested_multi_option(X)
                        | nested_multi_option(Y) X
                        ;

%rule with_word_seps(X): /* empty */
                   | X ' '+
                   ;

%%

program         : option(number)
                | multi_option(number, string)
                | with_word_seps(string)
                ;

%%

static int yylex(YYSTYPE *yylval, YYLTYPE *loc)
{
  return 0;
}

static int yyerror(YYLTYPE *loc, const char *str)
{
  return 0;
}

int main(int argc, char *argv[])
{
}
