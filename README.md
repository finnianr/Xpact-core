# Xpact-core

A pure Eiffel, incremental, libexpat-compatible XML parsing core.

[![Licence](https://img.shields.io/badge/licence-MIT-blue.svg)]()
[![EiffelStudio](https://img.shields.io/badge/EiffelStudio-25.12-green.svg)]()
[![Status](https://img.shields.io/badge/status-early%20stage-red.svg)]()

Xpact-core is a native Eiffel implementation of the XML parsing engine
at the heart of [libexpat](https://github.com/libexpat/libexpat), the
C library used by Python's `xml.parsers.expat`, Mozilla, and hundreds
of other projects across the open source ecosystem. Rather than
wrapping libexpat, Xpact-core re-implements its core algorithms
directly in Eiffel, ported from and informed by libexpat's own source,
then reshaped to take advantage of Design by Contract, void safety, and
Eiffel's object model throughout.

In benchmark testing against the same documents, Xpact-core has matched
or outperformed expat's own C implementation on several real-world XML
files. See [Benchmarks](#benchmarks) below.

## Why this exists

This project began as an experiment growing out of an essay,
["Finding a billion-user project for Eiffel: How DbC catches the
security flaws that Rust misses"](https://www.eiffel.org/blog/Finnian%20Reilly/2026/05/finding-billion-user-project-eiffel-how-dbc-catches-security-flaws-rust-misses),
which argued that Eiffel's Design by Contract mechanism can catch a
class of security-relevant logic errors that memory-safe languages like
Rust cannot, using libexpat's CVE history as concrete evidence.

Xpact-core is the proof of concept. It exists to demonstrate that a
formally specified, contract-bearing, void-safe Eiffel parser can be a
genuine drop-in replacement for a widely-deployed C library, without
sacrificing performance to get there.

## What's here

- **A pure Eiffel incremental parser core** (`XPACT_INCREMENTAL_PARSER`,
  soon to be renamed with an `XT_` prefix), supporting the same
  chunk-by-chunk streaming model as libexpat's `XML_Parse`, including
  partial-token carryover across chunk boundaries, buffer compaction,
  and growth.
- **A bucketed name interning cache** for element and attribute names,
  designed to eliminate redundant string allocation and to give
  CPU-cache-friendly, hash-free lookup performance.
- **A decomposed scanner architecture**, with separate classes for each
  major XML grammar production (tags, content, literals, entity
  references, the prolog, processing instructions and comments).
- **A pluggable encoding strategy** (ASCII, Latin-1, UTF-8, and a
  general fallback), allowing the tokenizer's hot path to specialise
  per-encoding without sacrificing correctness on the general case.
- **C-interoperable string classes** (`C_STRING_8`, `C_NULLED_STRING_8`)
  for zero-copy substring extraction and null-terminated C callback
  compatibility, without requiring GC pinning.

## Design principles

- **Specification-driven.** Contracts on every routine are derived
  directly from the XML specification and from known historical
  libexpat CVEs, expressing as preconditions and invariants the
  constraints that were missing when those vulnerabilities were
  discovered.
- **Zero-copy where possible.** The input buffer is wrapped, not
  copied. Tokens are shared substrings of the original buffer wherever
  correctness allows it.
- **GC-aware.** The parser is designed to run with the garbage
  collector disabled during a parse, since the hot path allocates
  almost nothing on the Eiffel heap. C-allocated string classes
  (`C_STRING_8`, `C_NULLED_STRING_8`) keep parse data outside the GC's
  view entirely.
- **Single object ownership per string.** Where ISE's `STRING_8`
  requires two heap-allocated objects per string (the instance and its
  `SPECIAL [CHARACTER_8]` area), the C-backed string classes here
  require only one.
- **Void-safe.** Xpact-core is being converted to a fully void-safe
  style as a deliberate design commitment, consistent with the broader
  argument that Eiffel's static safety guarantees matter for
  security-critical software.

## What this is not (yet)

Xpact-core is a parsing engine, not a complete drop-in replacement for
libexpat. It does not yet include:

- A C ABI bridge exposing a libexpat-compatible header
- DTD or external entity support
- A Python binding

These are deliberately left to downstream integration. See
[Relationship to xpact](#relationship-to-xpact) below.

## Relationship to xpact

[Anders Persson's xpact project](https://github.com/andersoxie/xpact)
is building a complete libexpat-compatible system: a native C ABI
bridge, callback handling, DTD and external entity support, and an
expat-compatible API surface, with its own independently developed
parser core.

Xpact-core and xpact's own parser are two independently developed
implementations of the same problem, built by two different people in
parallel, each with different design priorities. Rather than merge them
into one codebase, the current arrangement is:

- Xpact-core remains a standalone, independently useful Eiffel library
  for any Eiffel developer who wants XML parsing, void-safe and
  contract-driven, without taking on a C dependency.
- Anders is experimenting with consuming Xpact-core via inheritance,
  extending `XT_INCREMENTAL_PARSER` (or its current name,
  `XPACT_INCREMENTAL_PARSER`, pending the rename) to add the native
  bridge and callback layer he needs on top of it.
- If that integration proves successful, Xpact-core may become the
  shared core underneath xpact's broader feature set. If not, both
  projects continue to exist and develop independently, exchanging
  ideas and benchmark results as they have done so far.

Either outcome is a reasonable one. This is intentionally a loose,
federated collaboration between two developers with different working
styles, rather than a single managed codebase.

## Benchmarks

Benchmarks were run on real-world XML test data drawn from libexpat's
own test corpus, comparing Xpact-core against expat compiled with
`gcc -O2`, both single-threaded, on the same machine.

| Document | expat (C) | Xpact-core (Eiffel) | Result |
|---|---|---|---|
| `wordnet_glossary-20010201.rdf` (35MB, 149K+ tags) | 68 ms | 55 ms | **1.24x faster** |
| `ns_att_test.xml` (36MB, 50K rows, attribute-heavy) | 163 ms | 110 ms | **1.48x faster** |
| `recset.xml` (attribute and schema metadata heavy) | 142 ms | 95 ms | **1.49x faster** |

All runs produced identical tag occurrence counts to expat, confirming
correctness alongside the performance result.

These results are reproducible and are not yet independently verified
by a third party. Benchmark scripts are included under `examples/` for
anyone who wants to reproduce them.

> **A caveat worth stating plainly:** these benchmarks measure
> whole-document, in-memory parsing of a single string. They do not yet
> measure incremental, chunked-input streaming performance, which is
> the use case that matters most for libexpat's real-world deployment
> (network clients, web servers, file streaming). Xpact-core's
> incremental design supports this, but it has not yet been benchmarked
> specifically for it.

## Building

Xpact-core requires EiffelStudio (developed against version 25.12) and
has no external C library dependencies beyond the standard C library
itself.

```sh
git clone https://github.com/finnianr/Xpact-core.git
cd Xpact-core
# build instructions to be added
```

## Status

> This is an early-stage, actively developed proof of concept, not yet
> a production-ready library. Contracts are currently minimal in places
> and are being expanded. Void safety conversion is in progress. Expect
> rapid change.

## Licence

MIT.

## Background reading

- ["Finding a billion-user project for Eiffel: How DbC catches the
  security flaws that Rust misses"](https://www.eiffel.org/blog/Finnian%20Reilly/2026/05/finding-billion-user-project-eiffel-how-dbc-catches-security-flaws-rust-misses) — the essay that started this
- [libexpat](https://github.com/libexpat/libexpat) — the C library this
  project takes architectural inspiration from
- [xpact](https://github.com/andersoxie/xpact) — Anders Persson's
  complete libexpat-compatible system, independently developed in
  parallel
