#!/bin/bash
#
# Runs xml_reader -test_files against each directory/extension group
# listed in Tested-files.txt, logging results under docs/test-logs/.

. scripts/install_xml_reader.sh

MOUNT_POINT=/media/finnian/Windows
DEVICE=/dev/nvme0n1p3

if ! mountpoint -q "$MOUNT_POINT"; then
	sudo modprobe ntfs3
	sudo mkdir -p "$MOUNT_POINT"
	sudo mount -t ntfs3 "$DEVICE" "$MOUNT_POINT"
fi

source_dir=/media/finnian/Windows/Windows/System32

echo Scanning\: $source_dir
for extension in xml; do
	echo Testing against \*.$extension
	xml_reader -test_files "$source_dir/*.$extension"
done
echo

source_dir=/media/finnian/Windows/Windows/WinSxS

echo Scanning\: $source_dir
for extension in manifest; do
	echo Testing against \*.$extension
	xml_reader -test_files "$source_dir/*.$extension"
done
echo
