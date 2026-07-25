
. scripts/install_xml_reader.sh

export BENCHMARKS_DIR=$EIFFEL/library/Xpact-core/benchmarks

DURATION_MS=2000

echo
echo Benchmarking Eiffel Xpact-core and C eXpat
echo

for path in	$ISE_LIBRARY/library/vision2/vision2.ecf \
	tools/data/Legislation.xml \
	tools/data/recursive-entity-expansion.xml; do
	name=${path##*/}
	xml_reader -count_tags -duration $DURATION_MS -compare_to_expat $path
done

pushd .
cd $HOME/Dev/C/libexpat

for name in nes96.xml ns_att_test.xml recset.xml wordnet_glossary-20010201.rdf; do
	xml_reader -count_tags -compare_to_expat -duration $DURATION_MS testdata/largefiles/$name
done

popd


