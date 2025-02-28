/*
 * Simple JSON parser
 *
 * $ lrama -d json.y -o json.c && gcc -Wall json.c -o json && ./json <<< '{"foo": 42, "bar": [1, 2, 3], "baz": {"qux": true}}'
 * JSON parsed successfully!
 * $ lrama -d json.y -o json.c && gcc -Wall json.c -o json && ./json <<< '{"foo": invalid }'
 * Unexpected literal: invalid
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
    char *str;
    double num;
}

%token STRING NUMBER TRUE FALSE NULL_T

%locations

%%

json: object
    | array
    ;

object: '{' members? '}'
      ;

members: separated_nonempty_list(',', pair)
       ;

pair: STRING ':' value
    ;

array: '[' elements? ']'
     ;

elements: separated_nonempty_list(',', value)
        ;

value: STRING | NUMBER | object | array | TRUE | FALSE | NULL_T;

%%

static int yylex(YYSTYPE *yylval, YYLTYPE *loc) {
    int c;
    while ((c = getchar()) != EOF && isspace(c));
    if (c == EOF) return 0;
    if (c == '{' || c == '}' || c == '[' || c == ']' || c == ':' || c == ',') {
        return c;
    }
    if (c == '"') {
        char buffer[1024];
        int i = 0;
        while ((c = getchar()) != EOF && c != '"') {
            if (c == '\\') {
                int next = getchar();
                if (next == EOF)
                    break;
                buffer[i++] = next;
            } else {
                buffer[i++] = c;
            }
            if (i >= 1023)
                break;
        }
        buffer[i] = '\0';
        yylval->str = strdup(buffer);
        return STRING;
    }

    if (c == '-' || isdigit(c)) {
        char num_buffer[64];
        int i = 0;
        num_buffer[i++] = c;
        while ((c = getchar()) != EOF && (isdigit(c) || c == '.')) {
            num_buffer[i++] = c;
            if (i >= 63)
                break;
        }
        num_buffer[i] = '\0';
        if (c != EOF)
            ungetc(c, stdin);
        yylval->num = atof(num_buffer);
        return NUMBER;
    }

    if (isalpha(c)) {
        char word[16];
        int i = 0;
        word[i++] = c;
        while ((c = getchar()) != EOF && isalpha(c)) {
            word[i++] = c;
            if (i >= 15)
                break;
        }
        word[i] = '\0';
        if (c != EOF)
            ungetc(c, stdin);
        if (strcmp(word, "true") == 0)
            return TRUE;
        else if (strcmp(word, "false") == 0)
            return FALSE;
        else if (strcmp(word, "null") == 0)
            return NULL_T;
        else {
            fprintf(stderr, "Unexpected literal: %s\n", word);
            exit(1);
        }
    }

    fprintf(stderr, "Unexpected character: %c\n", c);
    return 0;
}

static int yyerror(YYLTYPE *loc, const char *s) {
    fprintf(stderr, "Error: %s\n", s);
    return 0;
}

int main() {
    yyparse();
    printf("JSON parsed successfully!\n");
    return 0;
}
