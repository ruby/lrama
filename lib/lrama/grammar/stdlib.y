/**********************************************************************

  stdlib.y

  This is lrama's standard library. It provides a number of
  parameterizing rule definitions, such as options and lists,
  that should be useful in a number of situations.

**********************************************************************/

/*
 * program: option(number)
 *
 * =>
 *
 * program: option_number
 * option_number: ε
 * option_number: number
 */
%rule option(X): /* empty */
               | X
               ;

/*
 * program: list(number)
 *
 * =>
 *
 * program: list_number
 * list_number: ε
 * list_number: list_number number
 */
%rule list(X): /* empty */
             | X list(X)
             ;

/*
 * program: nonempty_list(number)
 *
 * =>
 *
 * program: nonempty_list_number
 * nonempty_list_number: number
 * nonempty_list_number: nonempty_list_number number
 */
%rule nonempty_list(X): X
                      | X nonempty_list(X)
                      ;

/*
 * program: separated_nonempty_list(comma, number)
 *
 * =>
 *
 * program: separated_nonempty_list_comma_number
 * separated_nonempty_list_comma_number: number
 * separated_nonempty_list_comma_number: number, comma, separated_nonempty_list_comma_number
 */
%rule separated_nonempty_list(separator, X): X
                                           | X separator separated_nonempty_list(separator, X)
                                           ;

/*
 * program: separated_list(comma, number)
 *
 * =>
 *
 * program: separated_list_comma_number
 * separated_list_comma_number: option_separated_nonempty_list_comma_number
 * option_separated_nonempty_list_comma_number: ε
 * option_separated_nonempty_list_comma_number: separated_nonempty_list_comma_number
 * separated_nonempty_list_comma_number: number
 * separated_nonempty_list_comma_number: number, comma, separated_nonempty_list_comma_number
 */
%rule separated_list(separator, X): option(separated_nonempty_list(separator, X))
                                  ;

%%

%union{};
