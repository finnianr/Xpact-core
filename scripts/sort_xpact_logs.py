#!/usr/bin/env python3
"""
Sort 'Xpact VS eXpat <doc>.<suffix>.log' files into per-document directories,
renaming them to 'Xpact VS eXpat.<suffix>.log' in the process.

Example:
    'Xpact VS eXpat Legislation.xml.CRC-32-attribute.log'
        -> directory 'Legislation.xml/'
        -> file      'Xpact VS eXpat.CRC-32-attribute.log'

Usage:
    python3 sort_xpact_logs.py --source /path/to/files --dest /path/to/output
    python3 sort_xpact_logs.py --source /path/to/files --dest /path/to/output --move
    python3 sort_xpact_logs.py --source /path/to/files --dest /path/to/output --dry-run

By default files are COPIED (originals left untouched). Pass --move to move
them instead. Pass --dry-run to preview the plan without touching anything.

You can also point --file-list at a text file (one filename per line, quotes
optional) if you just want to see/validate the renaming plan without a
source directory containing the actual files.
"""

import argparse
import re
import shutil
from pathlib import Path

# Fixed prefix shared by all files
PREFIX = "Xpact VS eXpat"

# Known suffix tokens (the part after the document name, before ".log")
SUFFIXES = [
    "CRC-32-attribute",
    "CRC-32-cdata",
    "CRC-32-comment",
    "CRC-32-tag",
    "CRC-32-text",
    "tag_count",
]

# Build: "Xpact VS eXpat <docname>.<suffix>.log"
SUFFIX_PATTERN = "|".join(re.escape(s) for s in SUFFIXES)
FILENAME_RE = re.compile(
    r"^" + re.escape(PREFIX) + r" (?P<doc>.+)\.(?P<suffix>" + SUFFIX_PATTERN + r")\.log$"
)


def parse_filename(name: str):
    """Return (doc_dir, new_filename) or None if it doesn't match the pattern."""
    match = FILENAME_RE.match(name)
    if not match:
        return None
    doc = match.group("doc")
    suffix = match.group("suffix")
    new_name = f"{PREFIX}.{suffix}.log"
    return doc, new_name


def load_names_from_list(list_path: Path):
    names = []
    for line in list_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        # Strip surrounding single or double quotes, if present
        if len(line) >= 2 and line[0] == line[-1] and line[0] in "'\"":
            line = line[1:-1]
        names.append(line)
    return names


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--source", type=Path, help="Directory containing the actual log files")
    parser.add_argument("--dest", type=Path, required=True, help="Directory in which to create the per-document folders")
    parser.add_argument("--file-list", type=Path, help="Optional text file listing filenames (one per line) instead of scanning --source")
    parser.add_argument("--move", action="store_true", help="Move files instead of copying them")
    parser.add_argument("--dry-run", action="store_true", help="Show what would happen without touching any files")
    args = parser.parse_args()

    if args.file_list:
        names = load_names_from_list(args.file_list)
        source_dir = args.source  # may be None if only previewing
    elif args.source:
        names = [p.name for p in args.source.iterdir() if p.is_file()]
        source_dir = args.source
    else:
        parser.error("Provide either --source (to scan a directory) or --file-list (to preview from a list)")

    unmatched = []
    plan = []  # (original_name, doc_dir, new_name)

    for name in names:
        result = parse_filename(name)
        if result is None:
            unmatched.append(name)
            continue
        doc_dir, new_name = result
        plan.append((name, doc_dir, new_name))

    action_word = "Would move" if (args.dry_run and args.move) else \
                  "Would copy" if args.dry_run else \
                  "Moving" if args.move else "Copying"

    for original_name, doc_dir, new_name in plan:
        target_dir = args.dest / doc_dir
        target_path = target_dir / new_name
        print(f"{action_word}: '{original_name}' -> '{doc_dir}/{new_name}'")

        if args.dry_run:
            continue

        target_dir.mkdir(parents=True, exist_ok=True)

        if source_dir is None:
            continue  # nothing to actually copy/move, list-only preview

        src_path = source_dir / original_name
        if not src_path.exists():
            print(f"  WARNING: source file not found on disk, skipped: {src_path}")
            continue

        if args.move:
            shutil.move(str(src_path), str(target_path))
        else:
            shutil.copy2(str(src_path), str(target_path))

    if unmatched:
        print("\nFiles that did not match the expected pattern (left untouched):")
        for name in unmatched:
            print(f"  - {name}")

    print(f"\nDone. {len(plan)} file(s) matched, {len(unmatched)} unmatched.")


if __name__ == "__main__":
    main()
