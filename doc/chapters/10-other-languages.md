# Parsers in Other Languages

Lrama focuses on generating C parsers that integrate with CRuby. It does not
provide the multi-language backends that Bison offers (such as C++, Java, or
D). If you need those targets, consider using Bison directly.

That said, the generated C parser can be embedded in other language runtimes as
long as the host can call into C and provide the required lexer and error
handlers.
