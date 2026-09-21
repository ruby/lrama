/**********************************************************************

  stdlib.y

  This is lrama's standard library. It provides a number of
  parameterized rule definitions, such as options and lists,
  that should be useful in a number of situations.

**********************************************************************/

%code requires {
#ifndef LRAMA_STDLIB_LIST_H
#define LRAMA_STDLIB_LIST_H

#include <stdlib.h>
#include <stddef.h>

typedef struct lrama_list_node {
    void *val;
    struct lrama_list_node *next;
} lrama_list_node_t;

/* Create a new list node with a single value */
__attribute__((unused))
static lrama_list_node_t* lrama_list_new(void *val) {
    lrama_list_node_t *node = (lrama_list_node_t*)malloc(sizeof(lrama_list_node_t));
    if (node == NULL) {
        return NULL;
    }
    node->val = val;
    node->next = NULL;
    return node;
}

/* Append a value to the end of the list */
__attribute__((unused))
static lrama_list_node_t* lrama_list_append(lrama_list_node_t *list, void *val) {
    lrama_list_node_t *new_node = lrama_list_new(val);
    if (new_node == NULL) {
        return list;
    }

    if (list == NULL) {
        return new_node;
    }

    lrama_list_node_t *current = list;
    while (current->next != NULL) {
        current = current->next;
    }
    current->next = new_node;
    return list;
}

/* Free all nodes in the list (does not free the values themselves) */
__attribute__((unused))
static void lrama_list_free(lrama_list_node_t *list) {
    lrama_list_node_t *current = list;
    while (current != NULL) {
        lrama_list_node_t *next = current->next;
        free(current);
        current = next;
    }
}

/* Count the number of elements in the list */
__attribute__((unused))
static size_t lrama_list_length(const lrama_list_node_t *list) {
    size_t count = 0;
    const lrama_list_node_t *current = list;
    while (current != NULL) {
        count++;
        current = current->next;
    }
    return count;
}

/* Get the nth element (0-indexed), returns NULL if out of bounds */
__attribute__((unused))
static void* lrama_list_get(const lrama_list_node_t *list, size_t index) {
    const lrama_list_node_t *current = list;
    size_t i = 0;
    while (current != NULL) {
        if (i == index) {
            return current->val;
        }
        i++;
        current = current->next;
    }
    return NULL;
}

#endif /* LRAMA_STDLIB_LIST_H */

}

%%

// -------------------------------------------------------------------
// Options

/*
 * program: option(X)
 *
 * =>
 *
 * program: option_X
 * option_X: %empty
 * option_X: X
 */
%rule option(X)
                : /* empty */
                | X
                ;


/*
 * program: ioption(X)
 *
 * =>
 *
 * program: %empty
 * program: X
 */
%rule %inline ioption(X)
                : /* empty */
                | X
                ;

// -------------------------------------------------------------------
// Sequences

/*
 * program: preceded(opening, X)
 *
 * =>
 *
 * program: preceded_opening_X
 * preceded_opening_X: opening X
 */
%rule preceded(opening, X)
                : opening X { $$ = $2; }
                ;

/*
 * program: terminated(X, closing)
 *
 * =>
 *
 * program: terminated_X_closing
 * terminated_X_closing: X closing
 */
%rule terminated(X, closing)
                : X closing { $$ = $1; }
                ;

/*
 * program: delimited(opening, X, closing)
 *
 * =>
 *
 * program: delimited_opening_X_closing
 * delimited_opening_X_closing: opening X closing
 */
%rule delimited(opening, X, closing)
                : opening X closing { $$ = $2; }
                ;

// -------------------------------------------------------------------
// Lists

/*
 * program: list(X)
 *
 * =>
 *
 * program: list_X
 * list_X: %empty
 * list_X: list_X X
 */
%rule list(X)
                : /* empty */
                | list(X) X { $$ = lrama_list_append($1, (void*)$2); }
                ;

/*
 * program: nonempty_list(X)
 *
 * =>
 *
 * program: nonempty_list_X
 * nonempty_list_X: X
 * nonempty_list_X: nonempty_list_X X
 */
%rule nonempty_list(X)
                : X { $$ = lrama_list_new((void*)$1); }
                | nonempty_list(X) X { $$ = lrama_list_append($1, (void*)$2); }
                ;

/*
 * program: separated_nonempty_list(separator, X)
 *
 * =>
 *
 * program: separated_nonempty_list_separator_X
 * separated_nonempty_list_separator_X: X
 * separated_nonempty_list_separator_X: separated_nonempty_list_separator_X separator X
 */
%rule separated_nonempty_list(separator, X)
                : X { $$ = lrama_list_new((void*)$1); }
                | separated_nonempty_list(separator, X) separator X { $$ = lrama_list_append($1, (void*)$3); }
                ;

/*
 * program: separated_list(separator, X)
 *
 * =>
 *
 * program: separated_list_separator_X
 * separated_list_separator_X: %empty
 * separated_list_separator_X: X
 * separated_list_separator_X: separated_list_separator_X separator X
 */
%rule separated_list(separator, X)
                : /* empty */
                | X { $$ = lrama_list_new((void*)$1); }
                | separated_list(separator, X) separator X { $$ = lrama_list_append($1, (void*)$3); }
                ;
