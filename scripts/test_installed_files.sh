
# Find XML files to test Xpact against eXpat

. scripts/install_xml_reader.sh


extension=$1
echo Testing against \*.$extension
xml_reader -test_files -log docs/test-logs/star-dot-$extension.log \
	"$ISE_EIFFEL/*.$extension"



