# Lrama

[![Gem Version](https://badge.fury.io/rb/lrama.svg)](https://badge.fury.io/rb/lrama)
[![build](https://github.com/ruby/lrama/actions/workflows/test.yaml/badge.svg)](https://github.com/ruby/lrama/actions/workflows/test.yaml)

Lrama is LALR (1) parser generator written by Ruby. The first goal of this project is providing error tolerant parser for CRuby with minimal changes on CRuby parse.y file.

* [Features](#features)
* [Installation](#installation)
* [Usage](#usage)
* [Versions and Branches](#versions-and-branches)
* [Supported Ruby version](#supported-ruby-version)
* [Development](#development)
  * [How to generate parser.rb](#how-to-generate-parserrb)
  * [Test](#test)
  * [Profiling Lrama](#profiling-lrama)
  * [Build Ruby](#build-ruby)
* [Release flow](#release-flow)
* [License](#license)

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

### v0_6 (`master` branch)

This branch is for Ruby 3.4. `lrama_0_6` branch is created from this branch, once Ruby 3.4 is released.

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
$ rake build:parser
```

`parser.rb` is generated from `parser.y` by Racc.
Run the rake command when you update `parser.y` then commit changes of both files.

### Test

Running tests:

```shell
$ bundle install
$ bundle exec rspec
```

Running type check:

```shell
$ bundle install
$ bundle exec rbs collection install
$ bundle exec steep check
```

Running both of them:

```shell
$ bundle install
$ bundle exec rake
```

### Profiling Lrama

#### 1. Create parse.tmp.y in ruby/ruby

```shell
$ ruby tool/id2token.rb parse.y > parse.tmp.y
$ cp parse.tmp.y dir/lrama/tmp
```

#### 2. Enable Profiler

```diff
diff --git a/exe/lrama b/exe/lrama
index ba5fb06..2497178 100755
--- a/exe/lrama
+++ b/exe/lrama
@@ -3,4 +3,6 @@
 $LOAD_PATH << File.join(__dir__, "../lib")
 require "lrama"

-Lrama::Command.new.run(ARGV.dup)
+Lrama::Report::Profile.report_profile do
+  Lrama::Command.new.run(ARGV.dup)
+end
```

#### 3. Run Lrama

```shell
$ exe/lrama -o parse.tmp.c --header=parse.tmp.h tmp/parse.tmp.y
```

#### 4. Generate Flamegraph

```shell
$ stackprof --d3-flamegraph tmp/stackprof-cpu-myapp.dump > tmp/flamegraph.html
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

See LEGAL.md file.
