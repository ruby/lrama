# Introduction

Lrama is a parser generator written in Ruby. It takes a grammar file in a Bison-style format, constructs LALR(1) parsing tables, and renders a C parser from the configured skeleton. The project exists primarily to support CRuby parser development without depending on a system Bison installation or on behavior that changes across Bison versions.

The first audience for Lrama is CRuby contributors who work on `parse.y` and related parser tooling. It is also useful for developers who already know Yacc or Bison and want to understand which parts of that workflow are available in Lrama, and which parts are Lrama-specific.

## What Lrama Generates

The normal output is a C source file, `y.tab.c` by default. With `-d` or `-H`, Lrama also generates a header file. The generated parser expects a lexer function, a syntax error function, and the semantic value and location types implied by the grammar.

The default skeleton is `template/bison/yacc.c`. Lrama also ships `template/bison/yacc.h` for generated headers and `template/diagram/diagram.html` for syntax diagrams.

## Relationship To Bison

Lrama intentionally uses a Bison-style grammar surface, but it is not a complete implementation of every Bison feature. Common declarations such as `%token`, `%type`, `%union`, `%start`, precedence directives, semantic actions, named references, and generated C parsers are supported. Lrama also adds features such as parameterized rules, `%inline`, syntax diagram generation, and error-tolerant parser support.

When this manual calls a feature supported, it means the feature is accepted by the current repository implementation. Features that are not visible in `parser.y`, `lib/lrama/option_parser.rb`, the samples, or the tests are not described as supported.

## How To Read This Manual

Read [Concepts](01-concepts.md) before changing a grammar for the first time. Read [Examples](02-examples.md) to see complete files from the repository. Use [Grammar Files](03-grammar-files.md), [Invoking Lrama](09-invoking-lrama.md), and the appendices as reference material while maintaining a parser.

If you are coming from Bison, start with [Bison Compatibility](../appendices/c-bison-compatibility.md). If you are working on CRuby integration, read [Generated Parser and Integration](10-generated-parser-and-integration.md) and [Version Compatibility](12-version-compatibility.md).
