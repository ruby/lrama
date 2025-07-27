# Profiling Lrama

To help improve Lrama's processing speed and reduce its memory usage, Lrama supports two profiling options:

* Call-stack profiling using the stackprof gem
* Memory profiling using the memory_profiler gem

## Call-stack Profiling Lrama

### 1. Create parse.tmp.y in ruby/ruby

```shell
$ ruby tool/id2token.rb parse.y > parse.tmp.y
$ cp parse.tmp.y dir/lrama/tmp
```

### 2. Run Lrama

```shell
$ exe/lrama -o parse.tmp.c --header=parse.tmp.h --profile=call-stack tmp/parse.tmp.y
```

### 3. Generate Flamegraph

```shell
$ stackprof --d3-flamegraph tmp/stackprof-cpu-myapp.dump > tmp/flamegraph.html
```

## Memory Profiling Lrama

### 1. Create parse.tmp.y in ruby/ruby

```shell
$ ruby tool/id2token.rb parse.y > parse.tmp.y
$ cp parse.tmp.y dir/lrama/tmp
```

### 2. Run Lrama

```shell
$ exe/lrama -o parse.tmp.c --header=parse.tmp.h --profile=memory tmp/parse.tmp.y
```

Then "tmp/memory_profiler.txt" is generated.
