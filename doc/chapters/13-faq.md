# FAQ

## Does Lrama implement all of Bison?

No. Lrama supports Bison-style grammars but assumes specific settings (pure
parser, locations enabled, etc.). See [Concepts](01-concepts.md) for the exact
compatibility assumptions.

## Where is the documentation hosted?

The public documentation is published at https://ruby.github.io/lrama/.
This `doc/` directory is the source for that documentation.

## Can I use Lrama without Ruby?

Lrama is a Ruby tool and requires Ruby to run. The generated parser output is
in C, so you can compile and use it without Ruby once the code is generated.

## How do I profile Lrama?

See [Profiling](../development/profiling.md) for the profiling workflow.
