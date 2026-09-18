
. scripts/install_xml_reader.sh

if [ "$1" == "-xmlns" ]; then
	echo Name space parsing enabled
	opt_xmlns=$1
else
	opt_xmlns=
fi

file_path="${!#}"

echo
echo Comparing CRC-32 Xpact and eXpat for "${file_path##*/}"
echo

xml_reader -expat_compare $opt_xmlns "$file_path"
