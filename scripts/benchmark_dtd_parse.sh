
. scripts/install_xml_reader.sh

export BENCHMARKS_DIR=$EIFFEL/library/Xpact-core/benchmarks

DURATION_MS=2000

type_list="attlist element"

path=tools/data/DTD-attlist-default-values.xml

name=${path##*/}

echo
echo Benchmarking Eiffel Xpact-core and C eXpat for $name
echo

for type in $type_list; do
	echo Type\: $type in $name
	xml_reader -crc_32 $type -duration $DURATION_MS -compare_to_expat "$path"
done
