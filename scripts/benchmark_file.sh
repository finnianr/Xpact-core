
. scripts/install_xml_reader.sh

export BENCHMARKS_DIR=$EIFFEL/library/Xpact-core/benchmarks

DURATION_MS=2000

type_list="attribute cdata comment tag text"

if [ "$1" == "-xmlns" ]; then
	opt_xmlns=$1
else
	opt_xmlns=
fi

file_path="${!#}"

name=${file_path##*/}

if [ ! -f "$file_path" ]; then
	echo Usage\: benchmark_file.sh \[-xmlns\] \<xml-file-path\>
fi

echo
echo Benchmarking Eiffel Xpact-core and C eXpat for $name
echo

for type in $type_list; do
	echo Type\: $type in $name
	xml_reader -crc_32 $type $opt_xmlns -duration $DURATION_MS -compare_to_expat "$file_path"
done
