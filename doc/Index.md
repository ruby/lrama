# Lrama

[![Gem Version](https://badge.fury.io/rb/lrama.svg)](https://badge.fury.io/rb/lrama)
[![build](https://github.com/ruby/lrama/actions/workflows/test.yaml/badge.svg)](https://github.com/ruby/lrama/actions/workflows/test.yaml)


## Overview

Lrama is LALR (1) parser generator written by Ruby. The first goal of this project is providing error tolerant parser for CRuby with minimal changes on CRuby parse.y file.

## Installation

Lrama's installation is simple. You can install it via RubyGems.

```shell
$ gem install lrama
```

From source codes, you can install it as follows:

```shell
$ cd "$(lrama root)"
$ bundle install
$ bundle exec rake install
$ bundle exec lrama --version
lrama 0.7.0
```
## Usage

Lrama is a command line tool. You can generate a parser from a grammar file by running `lrama` command.

```shell
# "y.tab.c" and "y.tab.h" are generated
$ lrama -d sample/parse.y
```
Specify the output file with `-o` option. The following example generates "calc.c" and "calc.h".

```shell
# "calc", "calc.c", and "calc.h" are generated
$ lrama -d sample/calc.y -o calc.c && gcc -Wall calc.c -o calc && ./calc
Enter the formula:
1
=> 1
1+2*3
=> 7
(1+2)*3
=> 9
```

## Supported Ruby version

Lrama is executed with BASERUBY when building ruby from source code. Therefore Lrama needs to support BASERUBY, currently 2.5, or later version.

This also requires Lrama to be able to run with only default gems because BASERUBY runs with `--disable=gems` option.

## License

See [LEGAL.md](https://github.com/ruby/lrama/blob/master/LEGAL.md) file.
