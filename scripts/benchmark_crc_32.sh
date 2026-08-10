
. scripts/install_xml_reader.sh

export BENCHMARKS_DIR=$EIFFEL/library/Xpact-core/benchmarks

DURATION_MS=2000

echo
echo Benchmarking Eiffel Xpact-core and C eXpat
echo

type_list="attribute cdata comment pi-name pi-data tag text"

echo vision2.ecf
for type in $type_list; do
	echo Type: $type in vision2.ecf
	xml_reader -crc_32 $type -duration $DURATION_MS -compare_to_expat \
		$ISE_LIBRARY/library/vision2/vision2.ecf
	echo
done

pushd .

cd tools/data

for name in mandarin-names-and-text.xsl recursive-entity-expansion.xml Legislation.xml \
		DTD-attlist-default-values.xml mandarin-names-and-text.xsl ; do
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


