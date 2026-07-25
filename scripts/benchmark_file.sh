
. scripts/install_xml_reader.sh

export BENCHMARKS_DIR=$EIFFEL/library/Xpact-core/benchmarks

DURATION_MS=2000

type=$1
path=$2

name=${path##*/}

if [ ! -f "$path" ]; then
	echo Usage\: benchmark_file.sh \<type\> \<xml-file-path\>
	echo \(type can be \'tag_count\'\)
fi

echo
echo Benchmarking Eiffel Xpact-core and C eXpat for $name
echo

echo Type\: $type in $name

if [ "$type" = "tag_count" ]; then
	xml_reader -count_tags -compare_to_expat -duration $DURATION_MS $path
else
	xml_reader -crc_32 $type -duration $DURATION_MS -compare_to_expat $path
fi
