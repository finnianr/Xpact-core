
. scripts/install_xml_reader.sh

export BENCHMARKS_DIR=$EIFFEL/library/Xpact-core/benchmarks

DURATION_MS=2000

type_list="attribute cdata comment pi-name pi-data tag text"

path=$1

name=${path##*/}

if [ ! -f "$path" ]; then
	echo Usage\: benchmark_file.sh \<xml-file-path\>
fi

echo
echo Benchmarking Eiffel Xpact-core and C eXpat for $name
echo

xml_reader -count_tags -compare_to_expat -duration $DURATION_MS ""$path""

for type in $type_list; do
	echo Type\: $type in $name
	xml_reader -crc_32 $type -duration $DURATION_MS -compare_to_expat "$path"
done
