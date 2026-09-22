
# Basic XML files to test Xpact against eXpat including attack files

. scripts/install_xml_reader.sh

echo Testing against tools/data/\*.\*



if [ "$1" == "-xmlns" ]; then
	opt_xmlns=$1
else
	opt_xmlns=
fi

for dir_name in data data-large; do
	xml_reader -test_files $opt_xmlns "tools/$dir_name/*.*"
done

if [ "${!#}" == "large" ]; then
	echo
	pushd .
	
	cd $HOME/Dev/C/libexpat/testdata
	echo Testing against eXpat test data\: largefiles/\*.xml
	xml_reader -test_files $opt_xmlns "largefiles/*.xml"
	
	popd

else
	echo Skipped large test files
fi

