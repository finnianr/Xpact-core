#!/usr/bin/env python3
"""
Compare two CRC-32 trace logs (produced by different XML-parsing programs)
and report where the accumulated CRC sequence diverges permanently.

Each data line in the logs looks like:
    #0000001 (345563232): "urn:schemas-microsoft-com:rowset"

The two programs may split text content at slightly different points, which
shifts the sequence numbers and can cause the CRC stream to disagree for a
line or two before "re-syncing" back to the same values. This script walks
both files with two pointers, and whenever the CRC values stop matching it
looks ahead (within a bounded window) for a run of consecutive matching CRCs
in both files to decide whether the streams re-synced or diverged for good.
"""

import argparse
import re
import sys

LINE_RE = re.compile(r'^#(\d+)\s+\((\d+)\):\s*"(.*)"$')
CHECKSUM_RE = re.compile(r'^Checksum for \S+:\s*(\d+)\s*$')


def load_records(path):
    """Return (records, final_checksum) where records is a list of
    (seq:int, crc:int, text:str, lineno:int) for data lines, and
    final_checksum is the int from the trailing "Checksum for ..." line
    (or None if not present)."""
    records = []
    final_checksum = None
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        for lineno, line in enumerate(f, start=1):
            line = line.rstrip("\n")
            m = LINE_RE.match(line)
            if m:
                seq, crc, text = m.groups()
                records.append((int(seq), int(crc), text, lineno))
                continue
            m = CHECKSUM_RE.match(line)
            if m:
                final_checksum = int(m.group(1))
    return records, final_checksum


def find_resync(a, b, i, j, window, min_run):
    """
    Search for a resync point within `window` lines of (i, j) in a and b:
    a pair (i2, j2) such that the next `min_run` CRC values in a[i2:] and
    b[j2:] match exactly. Returns (i2, j2) or None if not found.
    Prefers the resync with the smallest total shift (i2-i)+(j2-j).
    """
    best = None
    best_shift = None
    max_i = min(len(a), i + window + min_run)
    max_j = min(len(b), j + window + min_run)
    for i2 in range(i, max_i):
        if i2 + min_run > len(a):
            break
        for j2 in range(j, max_j):
            if j2 + min_run > len(b):
                break
            shift = (i2 - i) + (j2 - j)
            if best_shift is not None and shift >= best_shift:
                continue
            ok = True
            for k in range(min_run):
                if a[i2 + k][1] != b[j2 + k][1]:
                    ok = False
                    break
            if ok:
                best = (i2, j2)
                best_shift = shift
    return best


def fmt(rec):
    seq, crc, text, lineno = rec
    if len(text) > 60:
        text = text[:57] + "..."
    return f'line {lineno}: #{seq:07d} ({crc}): "{text}"'


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("file_a")
    ap.add_argument("file_b")
    ap.add_argument("--window", type=int, default=25,
                     help="max lines to look ahead when searching for a resync (default 25)")
    ap.add_argument("--min-run", type=int, default=5,
                     help="consecutive matching CRCs required to confirm a resync (default 5)")
    ap.add_argument("--context", type=int, default=3,
                     help="lines of context to show around the final divergence (default 3)")
    args = ap.parse_args()

    a, checksum_a = load_records(args.file_a)
    b, checksum_b = load_records(args.file_b)

    print(f"{args.file_a}: {len(a)} data lines, final checksum={checksum_a}")
    print(f"{args.file_b}: {len(b)} data lines, final checksum={checksum_b}")
    print()

    i = j = 0
    temp_diverges = []

    while i < len(a) and j < len(b):
        if a[i][1] == b[j][1]:
            i += 1
            j += 1
            continue

        # mismatch at (i, j) -- try to find where things line up again
        resync = find_resync(a, b, i, j, args.window, args.min_run)
        if resync is None:
            # permanent divergence starts here
            print("=" * 70)
            print(f"PERMANENT DIVERGENCE starting at record #{a[i][0]} (file A) "
                  f"/ #{b[j][0]} (file B)")
            print("-" * 70)
            print("Context before (last matching lines):")
            for k in range(max(0, i - args.context), i):
                print("  A:", fmt(a[k]))
            for k in range(max(0, j - args.context), j):
                print("  B:", fmt(b[k]))
            print()
            print("First diverging lines:")
            for k in range(i, min(len(a), i + args.context)):
                print("  A:", fmt(a[k]))
            for k in range(j, min(len(b), j + args.context)):
                print("  B:", fmt(b[k]))
            print("=" * 70)

            if temp_diverges:
                print()
                print(f"({len(temp_diverges)} temporary divergence(s) were found and "
                      f"re-synced before this point -- see above.)")
            sys.exit(1)
        else:
            i2, j2 = resync
            temp_diverges.append((i, j, i2, j2))
            print(f"Temporary divergence: file A #{a[i][0]} (line {a[i][3]}) vs "
                  f"file B #{b[j][0]} (line {b[j][3]}) "
                  f"-- re-synced at file A #{a[i2][0]} / file B #{b[j2][0]} "
                  f"(shift A:{i2 - i}, B:{j2 - j})")
            i, j = i2, j2

    # If we got here, one (or both) files ran out without a permanent divergence
    if i < len(a) or j < len(b):
        print()
        print("=" * 70)
        print("Files matched until one ran out of data lines (no CRC divergence found).")
        if i < len(a):
            print(f"File A has {len(a) - i} extra trailing line(s), starting at "
                  f"#{a[i][0]} (line {a[i][3]}).")
        if j < len(b):
            print(f"File B has {len(b) - j} extra trailing line(s), starting at "
                  f"#{b[j][0]} (line {b[j][3]}).")
        print("=" * 70)
        sys.exit(2)
    else:
        print()
        print("All CRC values matched line-for-line to the end of both files.")
        sys.exit(0)


if __name__ == "__main__":
    main()
