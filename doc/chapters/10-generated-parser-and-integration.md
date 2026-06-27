# Generated Parser and Integration

Lrama's primary generated artifact is a C parser. Integration work is mostly about keeping the grammar, lexer, generated header, build rules, and runtime parser state consistent.

## Generated Files

By default:

```shell
$ lrama grammar.y
```

generates:

```text
y.tab.c
```

With `-d` or `-H`, Lrama also generates a header:

```text
y.tab.h
```

If `-o parser.c` is used with `-d`, the default header is `parser.h`.

## Skeletons And Templates

The default skeleton is:

```text
template/bison/yacc.c
```

The default header template is:

```text
template/bison/yacc.h
```

Use `-S FILE` or `--skeleton=FILE` to choose a different skeleton. A custom skeleton is an advanced integration point; keep it close to the expected output context and test generated parsers carefully.

## Project Build Integration

A typical build has these steps:

1. Run Lrama on the grammar.
2. Compile the generated C file.
3. Compile or link the lexer and supporting C files.
4. Include the generated header where token definitions and `YYSTYPE` are needed.
5. Run parser tests that exercise successful parses, syntax errors, and recovery paths.

## CRuby Integration

Lrama was designed so CRuby can generate its parser from a Bison-style `parse.y` with minimal changes. The repository branches track Ruby release lines, and the command must run in Ruby's build environment under BASERUBY.

When changing behavior that affects CRuby, verify both Lrama's test suite and a Ruby build that regenerates and compiles the parser.

## Non-C Backends

The current repository provides the C parser skeleton and syntax diagram template. It does not currently provide C++, D, Java, Ruby, or other language parser backends. Treat any such backend as future work unless it is present in the repository and covered by tests.

## Runtime Debugging

Generated parsers can use the standard `YYDEBUG` style supported by the skeleton. Grammar fixtures often define `YYDEBUG 1` and set `yydebug = 1` in `main` while testing parser behavior.
