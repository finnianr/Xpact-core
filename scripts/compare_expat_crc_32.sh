
. scripts/install_xml_reader.sh

file_path=$1

echo
echo Comparing CRC-32 Xpact and eXpat for "${file_path##*/}"
echo

xml_reader -expat_compare "$file_path"

return

for type in attribute attrib-name cdata comment doctype tag text pi-name pi-data xml-decl; do
	echo Type: $type
	xml_reader -crc_32 $type -duration 0 "$file_path"
	xml_crc_32 -type $type -duration 0 "$file_path"
	echo
done

