#!/bin/bash
#
# test_100K_plus_files.sh
#
# Runs xml_reader -test_files against each directory/extension group
# listed in Tested-files.txt, logging results under docs/test-logs/.

. scripts/install_xml_reader.sh

source_dir=/usr/share
log_dir=docs/test-logs/$(basename $source_dir)
echo Logging to\: $log_dir
mkdir -p $log_dir
echo Scanning\: $source_dir
for extension in glade rng policy xsl ui docbook xml svg; do
	echo Testing against \*.$extension
	xml_reader -test_files -log $log_dir/star-dot-$extension.log \
		"$source_dir/*.$extension"
done
echo

source_dir=$ISE_EIFFEL
log_dir=docs/test-logs/$(basename $source_dir)
echo Logging to\: $log_dir
mkdir -p $log_dir
echo Scanning\: $source_dir
for extension in xml eant ecf; do
	echo Testing against \*.$extension
	xml_reader -test_files -log $log_dir/star-dot-$extension.log \
		"$source_dir/*.$extension"
done
echo

source_dir=$HOME/.steam
log_dir=docs/test-logs/$(basename $source_dir)
echo Logging to\: $log_dir
mkdir -p $log_dir
echo Scanning\: $source_dir
for extension in manifest svg xml; do
	echo Testing against \*.$extension
	xml_reader -test_files -log $log_dir/star-dot-$extension.log \
		"$source_dir/*.$extension"
done
echo

source_dir=$HOME/.es
log_dir=docs/test-logs/$(basename $source_dir)
echo Logging to\: $log_dir
mkdir -p $log_dir
echo Scanning\: $source_dir
for extension in xml; do
	echo Testing against \*.$extension
	xml_reader -test_files -log $log_dir/star-dot-$extension.log \
		"$source_dir/*.$extension"
done
echo

. scripts/test_Windows_files.sh
