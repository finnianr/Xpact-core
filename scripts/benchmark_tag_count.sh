
. scripts/install_xml_reader.sh

export BENCHMARKS_DIR=$EIFFEL/library/Xpact-core/benchmarks

DURATION_MS=2000

echo
echo Benchmarking Eiffel Xpact-core and C eXpat
echo

echo vision2.ecf
xml_reader -count_tags -duration $DURATION_MS -compare_to_expat $ISE_LIBRARY/library/vision2/vision2.ecf

pushd .

cd tools/data

for name in mandarin-names-and-text.xsl recursive-entity-expansion.xml Legislation.xml \
		DTD-attlist-default-values.xml mandarin-names-and-text.xsl ; do
	
	xml_reader -count_tags -compare_to_expat -duration $DURATION_MS $name
done

cd $HOME/Dev/C/libexpat

for name in nes96.xml ns_att_test.xml recset.xml wordnet_glossary-20010201.rdf; do
	xml_reader -count_tags -compare_to_expat -duration $DURATION_MS testdata/largefiles/$name
done

popd


