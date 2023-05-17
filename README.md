# Lrama

Lrama is LALR (1) parser generator written by Ruby. The first goal of this project is providing error tolerant parser for CRuby with minimal changes on CRuby parse.y file.

## Features

* Bison style grammar file is supported with some assumptions
  * b4_locations_if is always true
  * b4_pure_if is always true
  * b4_pull_if is always false
  * b4_lac_if is always false
* Error Tolerance parser
  * Subset of [Repairing Syntax Errors in LR Parsers (Corchuelo et al.)](https://idus.us.es/bitstream/handle/11441/65631/Repairing%20syntax%20errors.pdf) algorithm is supported

## Installation

```shell
$ gem install lrama
```

From source codes,

```shell
$ cd "$(lrama root)"
$ bundle install
$ bundle exec rake install
$ bundle exec lrama --version
0.5.0
```

## Usage

```shell
# "y.tab.c" and "y.tab.h" are generated
$ lrama -d sample/parse.y
```

## Build Ruby

1. Install Lrama
2. Run `make YACC=lrama`

## License

See LEGAL.md file.
