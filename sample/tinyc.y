/*
 * Tiny C Parser
 *
 * This is a simple parser for a subset of the C language.
 * https://bellard.org/tcc/
 *
 * $ lrama -d tinyc.y -o tinyc.c && gcc -Wall tinyc.c -o tinyc && ./tinyc <<< 'main() { var i; i = 1; println("i = ", i); }'
 * The program is syntactically correct.
 * $ lrama -d tinyc.y -o tinyc.c && gcc -Wall tinyc.c -o tinyc && ./tinyc <<< 'main() { var = "invalid"; }'
 * Error: syntax error, unexpected '=', expecting IDENTIFIER
 *
 */

%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <ctype.h>
    #include <string.h>
%}

%code provides {
    static int yylex(YYSTYPE *lval, YYLTYPE *loc);
    static int yyerror(YYLTYPE *loc, const char *s);
}

%union {
    int i;
    char *str;
}

%token <i> NUMBER
%token <str> STRING IDENTIFIER
%token VAR IF ELSE RETURN WHILE FOR PRINTLN

%locations

%%

program: /* empty */
       | program external_definition
       ;

external_definition: IDENTIFIER '(' parameter_list? ')' compound_statement
                   | VAR IDENTIFIER opt_initializer ';'
                   | VAR IDENTIFIER '[' expr ']' ';'
                   ;

parameter_list: separated_nonempty_list(',', IDENTIFIER)
              ;

compound_statement: '{' local_variable_declaration? statement* '}'
                  ;


local_variable_declaration: VAR IDENTIFIER var_list_opt ';'
                          ;

var_list_opt: /* empty */
            | ',' IDENTIFIER var_list_opt
            ;

statement: expr ';'
         | compound_statement
         | IF '(' expr ')' statement else_opt
         | RETURN expr? ';'
         | WHILE '(' expr ')' statement
         | FOR '(' expr ';' expr ';' expr ')' statement
         ;

else_opt: /* empty */
        | ELSE statement
        ;

expr: primary_expr
    | IDENTIFIER '=' expr
    | IDENTIFIER '[' expr ']' '=' expr
    | expr '+' expr
    | expr '-' expr
    | expr '*' expr
    | expr '<' expr
    | expr '>' expr
    ;

primary_expr: IDENTIFIER
            | NUMBER
            | STRING
            | IDENTIFIER '[' expr ']'
            | IDENTIFIER '(' separated_list(',', expr) ')'
            | '(' expr ')'
            | PRINTLN '(' STRING ',' expr ')'
            ;

opt_initializer: /* empty */
    | '=' expr
    ;

%%

static int yylex(YYSTYPE *yylval, YYLTYPE *loc) {
    int c;

    while ((c = getchar()) == ' ' || c == '\t' || c == '\n');
    if (c == EOF)
        return 0;

    if (isdigit(c)) {
        ungetc(c, stdin);
        int val;
        scanf("%d", &val);
        yylval->i = val;
        return NUMBER;
    }

    if (isalpha(c) || c == '_') {
        char buf[128];
        int i = 0;
        buf[i++] = c;
        while ((c = getchar()) != EOF && (isalnum(c) || c == '_')) {
            if (i < (int)(sizeof(buf) - 1))
                buf[i++] = c;
        }
        buf[i] = '\0';
        if (c != EOF)
            ungetc(c, stdin);

        if (strcmp(buf, "var") == 0)
            return VAR;
        if (strcmp(buf, "if") == 0)
            return IF;
        if (strcmp(buf, "else") == 0)
            return ELSE;
        if (strcmp(buf, "return") == 0)
            return RETURN;
        if (strcmp(buf, "while") == 0)
            return WHILE;
        if (strcmp(buf, "for") == 0)
            return FOR;
        if (strcmp(buf, "println") == 0)
            return PRINTLN;

        yylval->str = strdup(buf);
        return IDENTIFIER;
    }

    if (c == '\"') {
        char buf[256];
        int i = 0;
        while ((c = getchar()) != '\"' && c != EOF) {
            buf[i++] = c;
        }
        buf[i] = '\0';
        yylval->str = strdup(buf);
        return STRING;
    }

    return c;
}

static int yyerror(YYLTYPE *loc, const char *s) {
    fprintf(stderr, "Error: %s\n", s);
    exit(1);
}

int main(void) {
    yyparse();
    printf("The program is syntactically correct.\n");
    return 0;
}
