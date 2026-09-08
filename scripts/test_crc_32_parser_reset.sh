
. scripts/install_xml_reader.sh

type=$1
file_path=$2

echo
echo Test Xpact parser yields same CRC-32 for "${file_path##*/}"
echo


echo Type: $type
xml_reader -crc_32 $type -repeat "$file_path"
#  -trace

