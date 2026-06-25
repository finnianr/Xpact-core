
clear
echo Installing xml_reader
cp -u examples/build/linux-x86-64/EIFGENs/classic/F_code/xml_reader ~/.local/bin

pushd .



echo
echo Benchmarking Eiffel Xpact and C eXpat
echo

cd $EIFFEL/library/Eiffel-Loop/test/data/XML 

xml_tag_counter Legislation.xml -duration 2000
echo

xml_reader count_tags Legislation.xml -duration 2000
echo


cd $HOME/Dev/C

for name in ns_att_test.xml recset.xml wordnet_glossary-20010201.rdf; do
	xml_tag_counter libexpat/testdata/largefiles/$name -duration 2000
	echo

	xml_reader count_tags libexpat/testdata/largefiles/$name -duration 2000
	echo
done


popd


