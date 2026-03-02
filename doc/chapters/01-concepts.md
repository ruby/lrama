# Concepts

This section introduces the ideas behind Lrama and how it differs from GNU Bison.
Lrama is a Ruby implementation of an LALR(1) parser generator, built to be a
drop-in replacement for the Ruby parser toolchain while keeping compatibility
with Bison-style grammars.

## Lrama at a glance

- **LALR(1) parser generator**: Lrama produces C parsers from grammar files.
- **Bison-style grammar files**: Most Bison directives are accepted, but there
  are compatibility constraints (see below).
- **Error tolerant parsing**: Lrama can generate parsers that attempt recovery
  using a subset of the algorithm described in *Repairing Syntax Errors in LR
  Parsers*.
- **Ruby-focused**: Lrama is written in Ruby and is used in the CRuby build
  process.

## Compatibility assumptions

Lrama is not a full Bison reimplementation. It intentionally assumes the
following Bison configuration when reading a grammar file:

- `b4_locations_if` is always true (location tracking is enabled).
- `b4_pure_if` is always true (pure parser).
- `b4_pull_if` is always false (no pull parser interface).
- `b4_lac_if` is always false (no LAC).

These assumptions simplify the code generation path and reflect how CRuby uses
a Bison-compatible parser.

## Inputs and outputs

A typical Lrama run takes a `.y` grammar file and produces:

- A parser implementation in C (default `y.tab.c`, or the file passed by `-o`).
- A header file (`y.tab.h`) when `-d` or `-H` is provided.
- Optional reports (`--report` / `--report-file`).
- Optional syntax diagram output (`--diagram`).

## Workflow stages

1. Write a grammar file (`.y`) using Bison-compatible syntax.
2. Run Lrama to generate the parser C code.
3. Compile the generated C code with the rest of your project.

For worked examples, see the [Examples](02-examples.md) section.
