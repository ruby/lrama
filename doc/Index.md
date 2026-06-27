# Lrama

Lrama is a Ruby implementation of a LALR(1) parser generator. It reads a Bison-style grammar file, builds parser tables, and emits a C parser. Its primary goal is to support CRuby parser development, including Bison-compatible grammar files, error-tolerant parsing work, parameterized grammar rules, inlining, syntax diagrams, and a toolchain that can run as part of Ruby's build.

## Quick Start

Install the released gem:

```shell
$ gem install lrama
$ lrama --version
```

From a checkout of this repository:

```shell
$ bundle install
$ bundle exec ruby exe/lrama --version
```

Generate and run the calculator sample:

```shell
$ bundle exec ruby exe/lrama -d sample/calc.y -o /tmp/calc.c
$ gcc -Wall /tmp/calc.c -o /tmp/calc
$ /tmp/calc
```

Generate a state report and a syntax diagram while developing a grammar:

```shell
$ bundle exec ruby exe/lrama -v --report-file=/tmp/calc.output sample/calc.y
$ bundle exec ruby exe/lrama --diagram=/tmp/calc.html sample/calc.y
```

## Manual

Start with the introduction and examples if you are new to Lrama. Use the grammar, invocation, directive, and option references when you are maintaining an existing grammar.

1. [Introduction](chapters/00-introduction.md)
2. [Installation and Conditions](chapters/00-installation-and-conditions.md)
3. [Concepts](chapters/01-concepts.md)
4. [Examples](chapters/02-examples.md)
5. [Grammar Files](chapters/03-grammar-files.md)
6. [Parser C Interface](chapters/04-parser-interface.md)
7. [Parser Algorithm](chapters/05-parser-algorithm.md)
8. [Error Recovery and Error Tolerance](chapters/06-error-recovery.md)
9. [Context Dependencies](chapters/07-context-dependencies.md)
10. [Debugging Your Parser](chapters/08-debugging.md)
11. [Invoking Lrama](chapters/09-invoking-lrama.md)
12. [Generated Parser and Integration](chapters/10-generated-parser-and-integration.md)
13. [History](chapters/11-history.md)
14. [Version Compatibility](chapters/12-version-compatibility.md)
15. [FAQ](chapters/13-faq.md)

## Appendices

- [Directive Reference](appendices/a-directive-reference.md)
- [Command Line Option Reference](appendices/b-command-line-option-reference.md)
- [Bison Compatibility](appendices/c-bison-compatibility.md)
- [Standard Library](appendices/d-standard-library.md)
- [Glossary](appendices/e-glossary.md)
- [Troubleshooting](appendices/f-troubleshooting.md)
- [License and Legal Notes](appendices/g-license-and-legal-notes.md)

## Development Documents

- [Profiling](development/profiling.md)
- [Compressed state table](development/compressed_state_table/main.md)

## Supported Ruby Version

Lrama is executed with BASERUBY when building Ruby from source. For that reason, Lrama must run on the BASERUBY version used by Ruby and must work with default gems only, because BASERUBY is executed with `--disable=gems`.

## License

See [LEGAL.md](../LEGAL.md) for the authoritative legal notice for this repository.
