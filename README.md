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

## Versions and Branches

### v0_5 (`master` branch)

This branch is for Ruby 3.3. `lrama_0_5` branch is created from this branch, once Ruby 3.3 is released.

### v0_4 (`lrama_0_4` branch)

This branch generates "parse.c" compatible with Bison 3.8.2 for ruby 3.0, 3.1, 3.2. The first version migrated to ruby is ["0.4.0"](https://github.com/ruby/ruby/pull/7798) therefore keep this branch for Bison compatible branch.

## Supported Ruby version

Lrama is executed with BASERUBY when building ruby from source code. Therefore Lrama needs to support BASERUBY, currently 2.5, or later version.

This also requires Lrama to be able to run with only default gems and bundled gems.

## Build Ruby

1. Install Lrama
2. Run `make YACC=lrama`

## Release flow

1. Update `Lrama::VERSION`
2. Release as a gem by `rake release`
3. Update Lrama in ruby/ruby by `cp -r LEGAL.md MIT exe lib template ruby/tool/lrama`
4. Create new release on [GitHub](https://github.com/ruby/lrama/releases)

## License

See LEGAL.md file.
