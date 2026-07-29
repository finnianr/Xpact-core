
# Find XML files to test Xpact against eXpat

. scripts/install_xml_reader.sh

install_dir=/media/finnian/Windows/Windows/WinSxS
#install_dir=$HOME/.steam

log_dir=docs/test-logs/$(basename $install_dir)

echo $log_dir
mkdir -p $log_dir

extension=$1
echo Testing against \*.$extension
xml_reader -test_files -log $log_dir/star-dot-$extension.log \
	"$install_dir/*.$extension"


source_dir=$HOME/.steam

log_dir=docs/test-logs/$(basename $source_dir)

echo Logging to\: $log_dir
mkdir -p $log_dir

echo Scanning\: $soure_dir
for extension in manifest svg xml; do
	echo Testing against \*.$extension
	xml_reader -test_files -log $log_dir/star-dot-$extension.log \
		"$soure_dir/*.$extension"
done
echo
