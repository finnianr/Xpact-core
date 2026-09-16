
. scripts/install_xml_reader.sh

type=$1
file_path=$2
file_name=${file_path##*/}
xpact_out_path=$HOME/Desktop/Xpact-$file_name-$type.txt
expat_out_path=$HOME/Desktop/eXpat-$file_name-$type.txt
#pushd .

echo
echo Comparing CRC-32 Xpact and eXpat for "$file_name"
echo

echo Xpact: xml_reader -crc_32 $type
xml_reader -crc_32 $type -trace -duration 0 "$file_path" > "$xpact_out_path"
echo
echo eXpat: xml_crc_32 -type $type
xml_crc_32 -type $type -trace -duration 0 "$file_path" > "$expat_out_path"

#popd


