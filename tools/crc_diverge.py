#!/usr/bin/env python3
"""
crc_diverge.py

Compare two files containing sequentially numbered CRC values
(format: "N. CRC" per line, e.g. "106. 353083530") and report:

  - every point where the CRC sequences diverge, noting whether
    they later realign (transient) or not (permanent)
  - the exact entry at which permanent divergence begins

Entry numbers themselves are ignored for comparison purposes (a
missing or extra entry in one file just shifts numbering) -- only
the sequence of CRC *values* is compared, using difflib to find
the longest matching runs between the two sequences.

Usage:
    python3 crc_diverge.py file_a.txt file_b.txt
"""

import re
import sys
import difflib

LINE_RE = re.compile(r'^(\d+)\.\s+(\d+)\s*$')


def parse_crc_file(path):
	"""Return list of (entry_number, crc_value) tuples in file order."""
	entries = []
	with open(path, 'r', encoding='utf-8', errors='replace') as f:
		for line in f:
			m = LINE_RE.match(line.strip())
			if m:
				entries.append((int(m.group(1)), int(m.group(2))))
	return entries


def find_matching_blocks(a_vals, b_vals):
	# autojunk=False: CRC values are effectively unique 32-bit numbers,
	# so we don't want difflib's "popular element" heuristic kicking in.
	sm = difflib.SequenceMatcher(a=a_vals, b=b_vals, autojunk=False)
	return [b for b in sm.get_matching_blocks() if b.size > 0]


def main():
	if len(sys.argv) != 3:
		print(f"Usage: {sys.argv[0]} <file_a> <file_b>")
		sys.exit(1)

	path_a, path_b = sys.argv[1], sys.argv[2]

	entries_a = parse_crc_file(path_a)
	entries_b = parse_crc_file(path_b)

	if not entries_a or not entries_b:
		print("Could not find any 'N. CRC' formatted lines in one or both files.")
		sys.exit(1)

	vals_a = [crc for _, crc in entries_a]
	vals_b = [crc for _, crc in entries_b]

	blocks = find_matching_blocks(vals_a, vals_b)

	print(f"{path_a}: {len(entries_a)} entries")
	print(f"{path_b}: {len(entries_b)} entries")
	print()

	if not blocks:
		print("No matching CRC values found between the two files at all.")
		return

	prev_a_end, prev_b_end = 0, 0
	for idx, blk in enumerate(blocks):
		gap_a = blk.a - prev_a_end
		gap_b = blk.b - prev_b_end

		if gap_a > 0 or gap_b > 0:
			a_start = entries_a[prev_a_end][0] if prev_a_end < len(entries_a) else None
			a_end = entries_a[blk.a - 1][0] if blk.a - 1 >= prev_a_end else None
			b_start = entries_b[prev_b_end][0] if prev_b_end < len(entries_b) else None
			b_end = entries_b[blk.b - 1][0] if blk.b - 1 >= prev_b_end else None

			print(f"--- Divergence #{idx + 1} (realigns after this) ---")
			print(f"  {path_a}: entries {a_start}..{a_end}  ({gap_a} entries differ)")
			print(f"  {path_b}: entries {b_start}..{b_end}  ({gap_b} entries differ)")
			print()

		a_first, a_last = entries_a[blk.a][0], entries_a[blk.a + blk.size - 1][0]
		b_first, b_last = entries_b[blk.b][0], entries_b[blk.b + blk.size - 1][0]
		print(f"Matching block: {path_a} #{a_first}-{a_last}  <->  "
			f"{path_b} #{b_first}-{b_last}  ({blk.size} CRCs match)")
		print()

		prev_a_end = blk.a + blk.size
		prev_b_end = blk.b + blk.size

	# Anything left over after the final matching block never matches again
	# (SequenceMatcher already searched the full remainder of both lists).
	last_blk = blocks[-1]
	tail_a = len(vals_a) - (last_blk.a + last_blk.size)
	tail_b = len(vals_b) - (last_blk.b + last_blk.size)

	print("=" * 60)
	if tail_a == 0 and tail_b == 0:
		print("Files converge and match completely through to the end.")
	else:
		last_common_a = entries_a[last_blk.a + last_blk.size - 1][0]
		last_common_b = entries_b[last_blk.b + last_blk.size - 1][0]
		next_a = entries_a[last_blk.a + last_blk.size][0] if tail_a > 0 else None
		next_b = entries_b[last_blk.b + last_blk.size][0] if tail_b > 0 else None

		print("PERMANENT DIVERGENCE (no further realignment after this point):")
		print(f"  Last matching entry:  {path_a} #{last_common_a}  ==  {path_b} #{last_common_b}")
		print(f"  First entry that never realigns:  {path_a} #{next_a}, {path_b} #{next_b}")


if __name__ == "__main__":
	main()
