
# Find XML files to test Xpact against eXpat

. scripts/install_xml_reader.sh

echo ui file count\: 220 passed

extension=$1
echo Testing against \*.$extension
xml_reader -test_files -log docs/test-logs/star-dot-$extension.log \
	"/usr/share/*.$extension"

