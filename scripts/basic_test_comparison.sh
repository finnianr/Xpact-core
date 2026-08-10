
# Basic XML files to test Xpact against eXpat including attack files

. scripts/install_xml_reader.sh

echo Testing against tools/data/\*.\*

xml_reader -test_files "tools/data/*.*"

if [ "$1" == "large" ]; then
	echo
	echo Testing against libexpat/testdata/largefiles/\*.xml
	xml_reader -test_files "$HOME/Dev/C/libexpat/testdata/largefiles/*.xml"
else
	echo Skipped large eXpat test files
fi

