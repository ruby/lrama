%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Context tracking for parser state */
typedef enum {
    CONTEXT_NORMAL,
    CONTEXT_FUNCTION_START
} ParserContext;

static ParserContext current_context = CONTEXT_NORMAL;

/* Predicate: Check if we're at the start of a function definition */
static int is_at_function_start(void) {
    return current_context == CONTEXT_FUNCTION_START;
}

/* Set context to function start (called by lexer/parser) */
void set_function_context(void) {
    current_context = CONTEXT_FUNCTION_START;
}

/* Reset context to normal */
void reset_context(void) {
    current_context = CONTEXT_NORMAL;
}

int yylex(void);
void yyerror(const char *s);
%}

%token IDENTIFIER
%token FUNCTION
%token ASYNC_KEYWORD
%token SEMICOLON
%token LPAREN RPAREN

%%

program
    : declaration_list
    ;

declaration_list
    : /* empty */
    | declaration_list declaration
    ;

/* "async" is context-sensitive:
   - Before function definition: keyword (ASYNC_KEYWORD)
   - Otherwise: regular identifier (IDENTIFIER)
*/
declaration
    : {is_at_function_start()}? IDENTIFIER FUNCTION LPAREN RPAREN
      {
        printf("Async function declaration: %s\n", "async");
        reset_context();
      }
    | FUNCTION LPAREN RPAREN
      {
        printf("Regular function declaration\n");
        reset_context();
      }
    | IDENTIFIER SEMICOLON
      {
        printf("Identifier usage: variable or expression\n");
        reset_context();
      }
    ;

%%

int yylex(void) {
    /* Simplified lexer for testing */
    return 0;
}

void yyerror(const char *s) {
    fprintf(stderr, "Parse error: %s\n", s);
}

int main(void) {
    printf("Context-sensitive keyword parser\n");
    return yyparse();
}
