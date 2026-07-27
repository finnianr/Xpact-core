
# Find XML files to test Xpact against eXpat

. scripts/install_xml_reader.sh

#install_dir=/media/finnian/Windows/Windows/System32
install_dir=$HOME/.cache

extension=$1
echo Testing against \*.$extension
xml_reader -test_files -log docs/test-logs/star-dot-$extension.log \
	"$install_dir/*.$extension"



