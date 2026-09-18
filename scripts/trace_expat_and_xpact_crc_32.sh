
. scripts/install_xml_reader.sh

type=$1
if [ "$2" == "-xmlns" ]; then
	echo Name space parsing enabled
	opt_xmlns=$2
else
	opt_xmlns=
fi

file_path="${!#}"
file_name=${file_path##*/}
xpact_out_path=$HOME/Desktop/Xpact$opt_xmlns-$file_name-$type.txt
expat_out_path=$HOME/Desktop/eXpat$opt_xmlns-$file_name-$type.txt
#pushd .

echo
echo Comparing CRC-32 Xpact and eXpat for "$file_name"
echo

echo Xpact: xml_reader -crc_32 $type
xml_reader -crc_32 $type $opt_xmlns -trace "$file_path" > "$xpact_out_path"
echo
echo eXpat: xml_crc_32 -type $type
xml_crc_32 -type $type $opt_xmlns -trace "$file_path" > "$expat_out_path"

#popd


