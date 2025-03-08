/*
 * Simple SQL parser
 *
 * $ lrama -d sql.y -o sql.c && gcc -Wall sql.c -o sql && ./sql
 * SQL Parser started. Enter SQL statements (end with semicolon):
 * SELECT id, name FROM users WHERE age > 18 AND age < 32;
 * => SQL statement parsed successfully
 *    SELECT (Type: 0)
 *      id (Type: 3)
 *        name (Type: 3)
 *      FROM (Type: 1)
 *        users (Type: 4)
 *        WHERE (Type: 2)
 *          AND (Type: 6)
 *            > (Type: 5)
 *              age (Type: 3)
 *              18 (Type: 7)
 *            < (Type: 5)
 *              age (Type: 3)
 *              32 (Type: 7)
 */

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

extern int yylineno;
extern char *yytext;

typedef struct {
    char *name;
    char *type;
} Symbol;

typedef struct ASTNode {
    int type;
    char *value;
    struct ASTNode *left;
    struct ASTNode *right;
} ASTNode;

enum {
    NODE_SELECT,
    NODE_FROM,
    NODE_WHERE,
    NODE_COLUMN,
    NODE_TABLE,
    NODE_CONDITION,
    NODE_OPERATOR,
    NODE_VALUE
};

ASTNode* new_node(int type, char *value)
{
    ASTNode *node = malloc(sizeof(ASTNode));
    node->type = type;
    node->value = value ? strdup(value) : NULL;
    node->left = NULL;
    node->right = NULL;
    return node;
}

ASTNode* connect_nodes(ASTNode *parent, ASTNode *left, ASTNode *right)
{
    parent->left = left;
    parent->right = right;
    return parent;
}

ASTNode *root = NULL;

void print_ast(ASTNode *node, int depth)
{
    if (node == NULL) return;

    for (int i = 0; i < depth; i++) printf("  ");

    printf("%s", node->value ? node->value : "NULL");
    printf(" (Type: %d)\n", node->type);

    print_ast(node->left, depth + 1);
    print_ast(node->right, depth + 1);
}
%}

%code provides {
    static int yylex(YYSTYPE *lval, YYLTYPE *loc);
    static int yyerror(YYLTYPE *loc, const char *s);
}

%union {
    char *sval;
    int ival;
    double dval;
    struct ASTNode *node;
}

%token <sval> ID STRING_LITERAL
%token <ival> INTEGER
%token <dval> FLOAT

%token SELECT FROM WHERE
%token AND OR NOT
%token EQ NE LT GT LE GE
%token COMMA SEMICOLON LPAREN RPAREN
%token CREATE TABLE INSERT INTO VALUES
%token DELETE UPDATE SET
%token INT VARCHAR DATE
%token AS

%type <node> select_stmt table_reference column_reference
%type <node> column_list table_list where_clause condition
%type <node> expr literal

%locations

%%

sql_stmt: select_stmt SEMICOLON
            {
              root = $1;
              printf("SQL statement parsed successfully\n");
              print_ast(root, 0);
            }
            ;

select_stmt: SELECT column_list FROM table_list where_clause
               {
                   $$ = new_node(NODE_SELECT, "SELECT");
                   $$->left = $2;
                   ASTNode *from_node = new_node(NODE_FROM, "FROM");
                   from_node->left = $4;
                   from_node->right = $5;
                   $$->right = from_node;
               }
               ;

column_list: column_reference { $$ = $1; }
           | column_list COMMA column_reference
               {
                   $$ = $1;
                   ASTNode *temp = $$;
                   while (temp->right != NULL) {
                       temp = temp->right;
                   }
                   temp->right = $3;
               }
               ;

column_reference: ID { $$ = new_node(NODE_COLUMN, $1); }
                | ID AS ID
                    {
                        $$ = new_node(NODE_COLUMN, $1);
                        ASTNode *alias_node = new_node(NODE_COLUMN, $3);
                        $$->right = alias_node;
                    }
                    ;

table_list: table_reference { $$ = $1; }
          | table_list COMMA table_reference
              {
                  $$ = $1;
                  ASTNode *temp = $$;
                  while (temp->right != NULL) {
                      temp = temp->right;
                  }
                  temp->right = $3;
              }
              ;

table_reference: ID { $$ = new_node(NODE_TABLE, $1); }
               | ID AS ID
                   {
                       $$ = new_node(NODE_TABLE, $1);
                       ASTNode *alias_node = new_node(NODE_TABLE, $3);
                       $$->right = alias_node;
                   }
                   ;

where_clause: { $$ = NULL; }
            | WHERE condition
                {
                    $$ = new_node(NODE_WHERE, "WHERE");
                    $$->left = $2;
                }
            ;

condition: expr { $$ = $1; }
         | condition AND condition
             {
                 $$ = new_node(NODE_OPERATOR, "AND");
                 $$->left = $1;
                 $$->right = $3;
             }
         | condition OR condition
             {
                 $$ = new_node(NODE_OPERATOR, "OR");
                 $$->left = $1;
                 $$->right = $3;
             }
         | NOT condition
             {
                 $$ = new_node(NODE_OPERATOR, "NOT");
                 $$->left = $2;
             }
         | LPAREN condition RPAREN { $$ = $2; }
         ;

expr: column_reference EQ literal
        {
            $$ = new_node(NODE_CONDITION, "=");
            $$->left = $1;
            $$->right = $3;
        }
    | column_reference NE literal
        {
            $$ = new_node(NODE_CONDITION, "!=");
            $$->left = $1;
            $$->right = $3;
        }
    | column_reference LT literal
        {
            $$ = new_node(NODE_CONDITION, "<");
            $$->left = $1;
            $$->right = $3;
        }
    | column_reference GT literal
        {
            $$ = new_node(NODE_CONDITION, ">");
            $$->left = $1;
            $$->right = $3;
        }
    | column_reference LE literal
        {
            $$ = new_node(NODE_CONDITION, "<=");
            $$->left = $1;
            $$->right = $3;
        }
    | column_reference GE literal
        {
            $$ = new_node(NODE_CONDITION, ">=");
            $$->left = $1;
            $$->right = $3;
        }
    ;

literal: INTEGER
           {
               char buffer[32];
               snprintf(buffer, sizeof(buffer), "%d", $1);
               $$ = new_node(NODE_VALUE, buffer);
           }
       | FLOAT
           {
               char buffer[32];
               snprintf(buffer, sizeof(buffer), "%f", $1);
               $$ = new_node(NODE_VALUE, buffer);
           }
       | STRING_LITERAL { $$ = new_node(NODE_VALUE, $1); }
       ;

%%

enum TOKEN {
    T_EOF = 0,
    T_SELECT = SELECT,
    T_FROM = FROM,
    T_WHERE = WHERE,
    T_ID = ID,
    T_INTEGER = INTEGER,
    T_FLOAT = FLOAT,
    T_STRING = STRING_LITERAL,
    T_COMMA = COMMA,
    T_SEMICOLON = SEMICOLON,
    T_EQ = EQ,
    T_NE = NE,
    T_LT = LT,
    T_GT = GT,
    T_LE = LE,
    T_GE = GE,
    T_LPAREN = LPAREN,
    T_RPAREN = RPAREN,
    T_AND = AND,
    T_OR = OR,
    T_NOT = NOT,
    T_CREATE = CREATE,
    T_TABLE = TABLE,
    T_INSERT = INSERT,
    T_INTO = INTO,
    T_VALUES = VALUES,
    T_DELETE = DELETE,
    T_UPDATE = UPDATE,
    T_SET = SET,
    T_INT = INT,
    T_VARCHAR = VARCHAR,
    T_DATE = DATE,
    T_AS = AS
};

char *yytext;
int yylineno = 1;
char input_buffer[1024];
int input_pos = 0;
int buffer_size = 0;

struct Keyword {
    char *word;
    int token;
} keywords[] = {
    {"SELECT", T_SELECT},
    {"FROM", T_FROM},
    {"WHERE", T_WHERE},
    {"AND", T_AND},
    {"OR", T_OR},
    {"NOT", T_NOT},
    {"CREATE", T_CREATE},
    {"TABLE", T_TABLE},
    {"INSERT", T_INSERT},
    {"INTO", T_INTO},
    {"VALUES", T_VALUES},
    {"DELETE", T_DELETE},
    {"UPDATE", T_UPDATE},
    {"SET", T_SET},
    {"INT", T_INT},
    {"VARCHAR", T_VARCHAR},
    {"DATE", T_DATE},
    {"AS", T_AS}
};

int get_char()
{
    if (input_pos >= buffer_size) {
        if (fgets(input_buffer, sizeof(input_buffer), stdin) == NULL)
            return EOF;

        buffer_size = strlen(input_buffer);
        input_pos = 0;
        return input_buffer[input_pos++];
    }
    return input_buffer[input_pos++];
}

void unget_char()
{
    if (input_pos > 0) {
        input_pos--;
    }
}

static int yylex(YYSTYPE *yylval, YYLTYPE *loc)
{
    static char lexeme[1024];
    int i = 0;
    int c;

    while ((c = get_char()) != EOF) {
        if (c == ' ' || c == '\t' || c == '\n') {
            if (c == '\n') yylineno++;
            continue;
        }
        break;
    }

    if (c == EOF) return 0;

    if (isalpha(c) != 0 || c == '_') {
        lexeme[i++] = c;
        while ((c = get_char()) != EOF && (isalnum(c) != 0 || c == '_')) {
            lexeme[i++] = c;
        }
        unget_char();
        lexeme[i] = '\0';

        for (int j = 0; j < sizeof(keywords) / sizeof(keywords[0]); j++) {
            if (strcasecmp(lexeme, keywords[j].word) == 0) {
                return keywords[j].token;
            }
        }

        yylval->sval = strdup(lexeme);
        return T_ID;
    }

    if (isdigit(c) != 0) {
        lexeme[i++] = c;
        while ((c = get_char()) != EOF && isdigit(c)) {
            lexeme[i++] = c;
        }

        if (c == '.') {
            lexeme[i++] = c;
            while ((c = get_char()) != EOF && isdigit(c)) {
                lexeme[i++] = c;
            }
            unget_char();
            lexeme[i] = '\0';
            yylval->dval = atof(lexeme);
            return T_FLOAT;
        } else {
            unget_char();
            lexeme[i] = '\0';
            yylval->ival = atoi(lexeme);
            return T_INTEGER;
        }
    }

    if (c == '\'') {
        while ((c = get_char()) != EOF && c != '\'') {
            lexeme[i++] = c;
        }
        if (c != '\'') {
            fprintf(stderr, "Unterminated string literal\n");
        }
        lexeme[i] = '\0';
        yylval->sval = strdup(lexeme);
        return T_STRING;
    }

    switch (c) {
        case ',': return T_COMMA;
        case ';': return T_SEMICOLON;
        case '(': return T_LPAREN;
        case ')': return T_RPAREN;
        case '=': return T_EQ;
        case '<':
            c = get_char();
            if (c == '=') return T_LE;
            if (c == '>') return T_NE;
            unget_char();
            return T_LT;
        case '>':
            c = get_char();
            if (c == '=') return T_GE;
            unget_char();
            return T_GT;
        case '!':
            c = get_char();
            if (c == '=') return T_NE;
            unget_char();
            fprintf(stderr, "Unexpected character: %c\n", c);
            break;
    }

    fprintf(stderr, "Unexpected character: %c\n", c);
    return -1;
}

static int yyerror(YYLTYPE *loc, const char *s)
{
    fprintf(stderr, "Error: %s (line %d)\n", s, yylineno);
    return -1;
}

int main()
{
    printf("SQL Parser started. Enter SQL statements (end with semicolon):\n");
    yyparse();
    return 0;
}
