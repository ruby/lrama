# Installation and Conditions

Lrama can be installed as a RubyGem or run directly from a repository checkout.

## Install From RubyGems

```shell
$ gem install lrama
$ lrama --version
```

## Run From Source

```shell
$ git clone https://github.com/ruby/lrama.git
$ cd lrama
$ bundle install
$ bundle exec ruby exe/lrama --version
```

To install the gem built from the checkout:

```shell
$ bundle exec rake install
```

## Basic Command Check

Generate a parser from the calculator sample:

```shell
$ bundle exec ruby exe/lrama -d sample/calc.y -o /tmp/calc.c
```

Compile it with a C compiler:

```shell
$ gcc -Wall /tmp/calc.c -o /tmp/calc
```

## Generated Parser Conditions

The generated parser is C code. It must be compiled together with the lexer, headers, and support code expected by the grammar. For example, a grammar using `%locations` or location references expects location-aware `yylex` and `yyerror` signatures.

Lrama's own command is written in Ruby. When Lrama is used while building Ruby, it must run under BASERUBY and with default gems only. Do not add runtime dependencies that are unavailable when Ruby is built with `--disable=gems`.

## Legal Notes

This repository is mostly distributed under the MIT License, with specific template files listed separately in [LEGAL.md](../../LEGAL.md). This manual summarizes how to use Lrama; it is not legal advice. When licensing terms matter for a release or redistribution, review `LEGAL.md`, the gemspec, and the relevant generated files with maintainers.
