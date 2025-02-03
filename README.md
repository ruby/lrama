# Lrama

[![Gem Version](https://badge.fury.io/rb/lrama.svg)](https://badge.fury.io/rb/lrama)
[![build](https://github.com/ruby/lrama/actions/workflows/test.yaml/badge.svg)](https://github.com/ruby/lrama/actions/workflows/test.yaml)
[![RubyDoc](https://img.shields.io/badge/%F0%9F%93%9ARubyDoc-documentation-informational.svg)](https://www.rubydoc.info/gems/lrama)

Lrama is LALR (1) parser generator written by Ruby. The first goal of this project is providing error tolerant parser for CRuby with minimal changes on CRuby parse.y file.

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
  - [Call-stack Profiling Lrama](#call-stack-profiling-lrama)
    - [1. Create parse.tmp.y in ruby/ruby](#1-create-parsetmpy-in-rubyruby)
    - [2. Enable Profiler](#2-enable-profiler)
    - [3. Run Lrama](#3-run-lrama)
    - [4. Generate Flamegraph](#4-generate-flamegraph)
  - [Memory Profiling Lrama](#memory-profiling-lrama)
    - [1. Create parse.tmp.y in ruby/ruby](#1-create-parsetmpy-in-rubyruby-1)
    - [2. Enable Profiler](#2-enable-profiler-1)
    - [3. Run Lrama](#3-run-lrama-1)
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
  * Providing a generic definition of parameterizing rules as a [standard library](lib/lrama/grammar/stdlib.y).
* Inlining
  * The %inline directive causes all references to symbols to be replaced with its definition.
  * Resolve shift/reduce conflicts without artificially altering the grammar file.

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

## Documentation

https://ruby.github.io/lrama/ provides a comprehensive guide to Lrama's features and usage.

## Versions and Branches

### v0_7 (`master` branch)

This branch is for Ruby 3.5. `lrama_0_7` branch is created from this branch, once Ruby 3.5 is released.

### v0_6 (`lrama_0_6` branch)

This branch is for Ruby 3.4.

### v0_5 (`lrama_0_5` branch)

This branch is for Ruby 3.3.

### v0_4 (`lrama_0_4` branch)

This branch generates "parse.c" compatible with Bison 3.8.2 for ruby 3.0, 3.1, 3.2. The first version migrated to ruby is ["0.4.0"](https://github.com/ruby/ruby/pull/7798) therefore keep this branch for Bison compatible branch.

## Supported Ruby version

Lrama is executed with BASERUBY when building ruby from source code. Therefore Lrama needs to support BASERUBY, currently 2.5, or later version.

This also requires Lrama to be able to run with only default gems because BASERUBY runs with `--disable=gems` option.

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

### Call-stack Profiling Lrama

#### 1. Create parse.tmp.y in ruby/ruby

```shell
$ ruby tool/id2token.rb parse.y > parse.tmp.y
$ cp parse.tmp.y dir/lrama/tmp
```

#### 2. Run Lrama

```shell
$ exe/lrama -o parse.tmp.c --header=parse.tmp.h --profile=call-stack tmp/parse.tmp.y
```

#### 3. Generate Flamegraph

```shell
$ stackprof --d3-flamegraph tmp/stackprof-cpu-myapp.dump > tmp/flamegraph.html
```

### Memory Profiling Lrama

#### 1. Create parse.tmp.y in ruby/ruby

```shell
$ ruby tool/id2token.rb parse.y > parse.tmp.y
$ cp parse.tmp.y dir/lrama/tmp
```

#### 2. Enable Profiler

```diff
diff --git a/exe/lrama b/exe/lrama
index 1aece5d141..f5f94cf7fa 100755
--- a/exe/lrama
+++ b/exe/lrama
@@ -3,5 +3,9 @@

 $LOAD_PATH << File.join(__dir__, "../lib")
 require "lrama"
+require 'memory_profiler'

-Lrama::Command.new.run(ARGV.dup)
+report = MemoryProfiler.report do
+  Lrama::Command.new.run(ARGV.dup)
+end
+report.pretty_print
```

#### 3. Run Lrama

```shell
$ exe/lrama -o parse.tmp.c --header=parse.tmp.h tmp/parse.tmp.y > report.txt
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
