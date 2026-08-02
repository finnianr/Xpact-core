#!/bin/bash
#
# test_100K_plus_files.sh
#
# Runs xml_reader -test_files against each directory/extension group

. scripts/install_xml_reader.sh

source_dir=/usr/share
echo Scanning\: $source_dir
for extension in glade rng policy xsl ui docbook xml svg; do
	echo Testing against \*.$extension
	xml_reader -test_files "$source_dir/*.$extension"
done
echo

source_dir=$ISE_EIFFEL
echo Scanning\: $source_dir
for extension in xml eant ecf; do
	echo Testing against \*.$extension
	xml_reader -test_files "$source_dir/*.$extension"
done
echo

source_dir=$HOME/.steam

echo Scanning\: $source_dir
for extension in manifest svg xml; do
	echo Testing against \*.$extension
	xml_reader -test_files "$source_dir/*.$extension"
done
echo

source_dir=$HOME/.es
echo Scanning\: $source_dir
for extension in xml; do
	echo Testing against \*.$extension
	xml_reader -test_files "$source_dir/*.$extension"
done
echo

source_dir=$HOME/Documents
echo Scanning\: $source_dir
for extension in docx ods odt; do
	echo Testing against \*.$extension
	xml_reader -test_files "$source_dir/*.$extension"
done
echo

. scripts/test_Windows_files.sh
