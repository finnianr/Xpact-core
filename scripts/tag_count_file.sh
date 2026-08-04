
. scripts/install_xml_reader.sh

path=$1

name=${path##*/}

if [ ! -f "$path" ]; then
	echo Usage\: benchmark_file.sh \<xml-file-path\>
fi

xml_reader -count_tags $path

