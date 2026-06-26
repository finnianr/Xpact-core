
clear
echo Installing xml_reader
cp -u examples/build/linux-x86-64/EIFGENs/classic/F_code/xml_reader ~/.local/bin

export BENCHMARKS_DIR=$EIFFEL/library/Xpact-core/benchmarks

DURATION_MS=2000

pushd .

echo
echo Benchmarking Eiffel Xpact-core and C eXpat
echo

cd $EIFFEL/library/Eiffel-Loop

xml_reader -count_tags -duration $DURATION_MS -compare_to_expat test/data/XML/Legislation.xml

cd $HOME/Dev/C/libexpat

for name in ns_att_test.xml recset.xml wordnet_glossary-20010201.rdf; do
	xml_reader -count_tags -compare_to_expat -duration $DURATION_MS testdata/largefiles/$name
done


popd


