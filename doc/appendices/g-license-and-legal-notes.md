# License and Legal Notes

The authoritative legal notice for this repository is [LEGAL.md](../../LEGAL.md). This appendix is a practical guide for documentation readers and is not legal advice.

## Repository Notice

`LEGAL.md` states that all files in this distribution are covered under the MIT License except for specific files listed separately.

## GPL-Listed Template Files

`LEGAL.md` lists these files as licensed under GNU General Public License version 3 or later:

```text
template/bison/_yacc.h
template/bison/yacc.c
template/bison/yacc.h
```

Review those files directly for their license headers and any special exception text before redistributing templates, modified templates, or generated output in a release-sensitive context.

## Generated Parsers

Generated parser licensing can depend on the skeleton and template text used to create the generated file. When that matters, review:

- `LEGAL.md`
- The selected skeleton file
- The generated file header
- The gemspec and release packaging
- Project-specific redistribution requirements

Ask maintainers for review before making strong claims about generated parser licensing.

## Bison Manual Text

This manual can follow a general learning path familiar to Bison users, but it must not copy Bison manual prose. Lrama documentation should explain Lrama's own behavior, examples, and limitations in original wording based on this repository.
