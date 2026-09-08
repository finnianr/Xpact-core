
. scripts/install_xml_reader.sh

file_path=$1

echo
echo Comparing CRC-32 Xpact and eXpat for "${file_path##*/}"
echo

xml_reader -expat_compare "$file_path"
