
. scripts/install_xml_reader.sh

file_path=$1

#pushd .

echo
echo Comparing CRC-32 Xpact and eXpat for "${file_path##*/}"
echo

for type in text cdata comment tag attribute; do
	echo Type: $type
	xml_reader -crc_32 $type -duration 0 $file_path
	xml_crc_32 -type $type -duration 0 $file_path
	echo
done


#popd


