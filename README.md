# Lrama

[![Gem Version](https://badge.fury.io/rb/lrama.svg)](https://badge.fury.io/rb/lrama)
[![build](https://github.com/ruby/lrama/actions/workflows/test.yaml/badge.svg)](https://github.com/ruby/lrama/actions/workflows/test.yaml)
[![RubyDoc](https://img.shields.io/badge/%F0%9F%93%9ARubyDoc-documentation-informational.svg)](https://www.rubydoc.info/gems/lrama)

Lrama (pronounced in the same way as the noun “llama” in English) is LALR (1) parser generator written by Ruby. The first goal of this project is providing error tolerant parser for CRuby with minimal changes on CRuby parse.y file.

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Documentation](#documentation)
- [Versions and Branches](#versions-and-branches)
  - [v0\_7 (`master` branch)](#v0_7-master-branch)
  - [v0\_6 (`lrama_0_6` branch)](#v0_6-lrama_0_6-branch)
  - [v0\_5 (`lrama_0_5` branch)](#v0_5-lrama_0_5-branch)
  - [v0\_4 (`lrama_0_4` branch)](#v0_4-lrama_0_4-branch)
- [Supported Ruby version](#supported-ruby-version)
- [Development](#development)
  - [How to generate parser.rb](#how-to-generate-parserrb)
  - [How to Write a Type Signature](#how-to-write-a-type-signature)
  - [Test](#test)
  - [Build Ruby](#build-ruby)
- [Release flow](#release-flow)
- [License](#license)

## Features

* Bison style grammar file is supported with some assumptions
  * b4_locations_if is always true
  * b4_pure_if is always true
  * b4_pull_if is always false
  * b4_lac_if is always false
* Error Tolerance parser
  * Subset of [Repairing Syntax Errors in LR Parsers (Corchuelo et al.)](https://idus.us.es/bitstream/handle/11441/65631/Repairing%20syntax%20errors.pdf) algorithm is supported
* Parameterizing rules
  * The definition of a non-terminal symbol can be parameterized with other (terminal or non-terminal) symbols.
  * Providing a generic definition of parameterized rules as a [standard library](lib/lrama/grammar/stdlib.y).
* Inlining
  * The %inline directive causes all references to symbols to be replaced with its definition.
  * Resolve shift/reduce conflicts without artificially altering the grammar file.
* Syntax Diagrams
  * Easily generate syntax diagrams from the grammar file.
  * These visual diagrams are an useful development tool for grammar development and can also function as automatic self-documentation.

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
lrama 0.7.0
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

## Documentation

https://ruby.github.io/lrama/ provides a comprehensive guide to Lrama's features and usage.

## Versions and Branches

### v0_7 (`master` branch)

This branch is for Ruby 4.0. `lrama_0_7` branch is created from this branch, once Ruby 4.0 is released.

### v0_6 (`lrama_0_6` branch)

This branch is for Ruby 3.4.

### v0_5 (`lrama_0_5` branch)

This branch is for Ruby 3.3.

### v0_4 (`lrama_0_4` branch)

This branch generates "parse.c" compatible with Bison 3.8.2 for ruby 3.0, 3.1, 3.2. The first version migrated to ruby is ["0.4.0"](https://github.com/ruby/ruby/pull/7798) therefore keep this branch for Bison compatible branch.

## Supported Ruby version

See [Supported Ruby version](/doc/Index.md#supported-ruby-version) in doc.

## Development

### How to generate parser.rb

```shell
$ bundle exec rake build:parser
```

`parser.rb` is generated from `parser.y` by Racc.
Run the rake command when you update `parser.y` then commit changes of both files.

### How to Write a Type Signature

We use [Steep](https://github.com/soutaro/steep) for type checking and [rbs-inline](https://github.com/soutaro/rbs-inline) for type declarations.

Currently, type signatures are declared in the [sig/lrama](https://github.com/ruby/lrama/blob/master/sig/lrama) directory. However, these files will be replaced with `rbs-inline`. This means type signatures should be written directly in the source code.

For guidance on writing type signatures, refer to the [Syntax Guide](https://github.com/soutaro/rbs-inline/wiki/Syntax-guide) in the rbs-inline documentation.

### Test

Running tests:

```shell
$ bundle install
$ bundle exec rspec
# or
$ bundle exec rake spec
```

Running type check:

```shell
$ bundle install
$ bundle exec rbs collection install
$ bundle exec steep check
# or
$ bundle exec rake steep
```

Running both of them:

```shell
$ bundle install
$ bundle exec rake
```

### Build Ruby

1. Install Lrama
2. Run `make main`

## Release flow

1. Update `Lrama::VERSION` and NEWS.md
2. Release as a gem by `rake release`
3. Update Lrama in ruby/ruby by `cp -r LEGAL.md NEWS.md MIT exe lib template ruby/tool/lrama`
4. Create new release on [GitHub](https://github.com/ruby/lrama/releases)

## License

See [LEGAL.md](./LEGAL.md) file.
