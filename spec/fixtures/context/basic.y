/*
 * This is comment for this file.
 */

%require "3.0"

%{
// Prologue
%}

%expect 0
%define api.pure
%define parse.error verbose

%printer {
    print_int();
} <i>
%printer {
    print_token();
} tNUMBER tSTRING
%destructor {
    printf("destructor for i: %d\n", $$);
    printf("line for i: %d\n", __LINE__);
} <i>
%error-token {
    $$ = 100;
} tNUMBER

%lex-param {struct lex_params *p}
%parse-param {struct parse_params *p}

%initial-action
{
    initial_action_func(@$);
};

%union {
    int i;
    long l;
    char *str;
}

%token EOI 0 "EOI"
%token <i> '\\'  "backslash"
%token <i> '\13' "escaped vertical tab"
%token <i> keyword_class
%token <i> keyword_class2
%token <l> tNUMBER
%token <str> tSTRING
%token <i> keyword_end "end"
%token tPLUS  "+"
%token tMINUS "-"
%token tEQ    "="
%token tEQEQ  "=="

%type <i> class /* comment for class */

%nonassoc tEQEQ
%left  tPLUS tMINUS '>'
%right tEQ

%%

program: class { code $1; }
       | '+' strings_1
       | '-' strings_2
       ;

class : keyword_class tSTRING keyword_end %prec tPLUS
          { code $1; code $2; code $$; }
      | keyword_class tSTRING '!' { code @1; code @$; } keyword_end %prec "="
      ;

strings_1: string_1
         ;

strings_2: string_1
         | string_2
         ;

string_1: string
        ;

string_2: string '+'
        ;

string: tSTRING
      ;

%%

// Epilogue
