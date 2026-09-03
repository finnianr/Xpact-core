#!/usr/bin/env python3
"""
Scan a directory (non-recursively) for files that contain XML and, among
those, prefix the filename with "DT-" for any file whose content includes
a DOCTYPE declaration (<!DOCTYPE ...>).

Detection is done with plain byte-string scanning rather than a real XML
parser, so that files which are not strictly well-formed XML (e.g. a
deliberately truncated test fixture like albert-4096-bytes.svg, which is
pseudo-XML rather than a complete document) are still recognised instead
of being rejected on a parse error.

Usage:
    doctype_prefix_rename.py [directory] [--dry-run]

If `directory` is omitted, the current working directory is used.
"""

import argparse
import re
import sys
from pathlib import Path

DOCTYPE_RE = re.compile(rb"<!DOCTYPE\b", re.IGNORECASE)
XML_DECL_RE = re.compile(rb"<\?xml\b", re.IGNORECASE)
PREFIX = "DT-"


def looks_like_xml(data: bytes) -> bool:
    """Heuristic: does `data' look like XML/markup content?

    Deliberately avoids a real XML parser so that malformed or truncated
    XML-like files are still recognised rather than rejected on a parse
    error.
    """
    stripped = data.lstrip()
    if stripped.startswith(b"\xef\xbb\xbf"):  # UTF-8 BOM
        stripped = stripped[3:].lstrip()
    if XML_DECL_RE.match(stripped):
        return True
    return stripped.startswith(b"<")


def has_doctype(data: bytes) -> bool:
    return DOCTYPE_RE.search(data) is not None


def rename_with_doctype_prefix(directory: Path, dry_run: bool) -> None:
    for entry in sorted(directory.iterdir()):
        if not entry.is_file():
            continue
        if entry.name.startswith(PREFIX):
            continue

        try:
            data = entry.read_bytes()
        except OSError as exc:
            print(f"skip (unreadable): {entry.name}: {exc}", file=sys.stderr)
            continue

        if not looks_like_xml(data):
            continue
        if not has_doctype(data):
            continue

        target = entry.with_name(PREFIX + entry.name)
        if target.exists():
            print(f"skip (target exists): {entry.name} -> {target.name}", file=sys.stderr)
            continue

        if dry_run:
            print(f"would rename: {entry.name} -> {target.name}")
        else:
            entry.rename(target)
            print(f"renamed: {entry.name} -> {target.name}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Prefix XML files containing a DOCTYPE declaration with 'DT-'."
    )
    parser.add_argument(
        "directory", nargs="?", default=".",
        help="Directory to scan (non-recursively). Defaults to the current directory."
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Show what would be renamed without changing anything."
    )
    args = parser.parse_args()

    directory = Path(args.directory)
    if not directory.is_dir():
        parser.error(f"not a directory: {directory}")

    rename_with_doctype_prefix(directory, args.dry_run)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
