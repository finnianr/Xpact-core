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
-
