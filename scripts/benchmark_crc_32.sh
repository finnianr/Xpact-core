
. scripts/install_xml_reader.sh

export BENCHMARKS_DIR=$EIFFEL/library/Xpact-core/benchmarks$1

DURATION_MS=2000

echo
echo Benchmarking Eiffel Xpact-core and C eXpat
echo

	
if [ "$1" == "-xmlns" ]; then
	echo Namespace parsing enabled
	pushd tools/data-large
	
	type_list="attribute comment tag text"
	for name in ../data/xmlns-mandarin-stylesheet.xsl steam_icon_500.svg  word-document.xml; do
		for type in $type_list; do
			echo Type: $type in $name
			xml_reader -crc_32 $type -duration $DURATION_MS -compare_to_expat $name
			echo
		done
	done
	popd
	
elif [ "$1" == "-dtd" ]; then
	pushd tools/data-large

	echo
	echo Benchmarking Eiffel Xpact-core and C eXpat for DTD parsing
	echo

	for type in attlist element; do
		echo Type\: $type in $name
		xml_reader -crc_32 $type -duration $DURATION_MS -compare_to_expat DTD-attlist-default-values.xml
	done
	popd
else
	type_list="attribute cdata comment tag text"
	echo vision2.ecf
	for type in $type_list; do
		echo Type: $type in vision2.ecf
		xml_reader -crc_32 $type -duration $DURATION_MS -compare_to_expat \
			$ISE_LIBRARY/library/vision2/vision2.ecf
		echo
	done

	pushd .

	cd tools/data

	for name in mandarin-names-and-text.xsl recursive-entity-expansion.xml \
			DTD-attlist-default-values.xml Legislation.xml; do
		for type in $type_list; do
			echo Type: $type in $name
			xml_reader -crc_32 $type -duration $DURATION_MS -compare_to_expat $name
			echo
		done
	done

	cd $HOME/Dev/C/libexpat/testdata

	for name in nes96.xml ns_att_test.xml recset.xml wordnet_glossary-20010201.rdf; do
		for type in $type_list; do
			echo Type: $type in $name
			xml_reader -crc_32 $type -duration $DURATION_MS -compare_to_expat largefiles/$name
			echo
		done
	done

	popd
fi

