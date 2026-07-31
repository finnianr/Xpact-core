#!/bin/bash
#
# Runs xml_reader -test_files against each directory/extension group
# listed in Tested-files.txt, logging results under docs/test-logs/.

. scripts/install_xml_reader.sh

find /media/finnian/Windows/Windows/System32 -type f -iname '*.xml' -exec sh -c '
	for f; do
		bom=$(head -c2 "$f" | od -An -tx1 | tr -d " ")
		case "$bom" in fffe|feff) printf "%s\t%s\n" "$(stat -c%s "$f")" "$f" ;; esac
	done
' _ {} + | sort -n | tail -n1
