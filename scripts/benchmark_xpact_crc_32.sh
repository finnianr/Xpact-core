
clear
echo Installing xml_reader
cp -u examples/build/linux-x86-64/EIFGENs/classic/F_code/xml_reader ~/.local/bin

export BENCHMARKS_DIR=$EIFFEL/library/Xpact-core/benchmarks

DURATION_MS=2000

echo
echo Benchmarking Eiffel Xpact-core and C eXpat
echo

for path in	$ISE_LIBRARY/library/vision2/vision2.ecf \
	examples/data/Legislation.xml; do
	name=${path##*/}
	for type in text cdata comment tag attribute; do
		echo Type: $type in $name
		xml_reader -crc_32 $type -duration $DURATION_MS -compare_to_expat $path
		echo
	done
done

pushd .

cd $HOME/Dev/C/libexpat

for name in nes96.xml ns_att_test.xml recset.xml wordnet_glossary-20010201.rdf; do
	for type in text cdata comment tag attribute; do
		echo Type: $type in $name
		xml_reader -crc_32 $type -duration $DURATION_MS -compare_to_expat testdata/largefiles/$name
		echo
	done
done

popd


