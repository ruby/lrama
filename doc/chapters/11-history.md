# History

Lrama is part of the long Yacc and Bison parser-generator tradition, but its design is shaped by CRuby's maintenance needs.

## From Yacc And Bison To Lrama

Yacc established the grammar-file model used by many parser generators: declarations, grammar rules, semantic actions, and generated C parsers. GNU Bison extended that model with more diagnostics, parser options, skeletons, language backends, and documentation.

CRuby historically used Bison to generate its parser. That created practical dependency issues: developers and build systems needed a compatible Bison version, and generated parser behavior could depend on external tool details.

## Why Ruby Needed Lrama

Lrama gives Ruby a parser generator written in Ruby and maintained with Ruby's needs in mind. It allows Ruby parser work to happen in the same language ecosystem as the project using it, and it lets CRuby-specific parser features be implemented directly in Lrama.

The project goals include:

- Reading Bison-style grammar files.
- Generating parser output compatible with CRuby's needs.
- Supporting error-tolerant parser work.
- Providing parameterized rules and inlining for large grammar maintainability.
- Avoiding a build-time dependency on a system Bison executable for supported Ruby branches.

## Current Direction

The current manual focuses on the implemented repository behavior: a Ruby command-line tool, Bison-style grammar parsing, LALR(1) and opt-in IELR state generation, generated C parsers, syntax diagrams, reports, and CRuby-oriented integration.

Future features should be documented only after they are implemented, tested, and merged.
