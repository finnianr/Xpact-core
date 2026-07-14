
clear
echo Installing xml_reader
cp -u examples/build/linux-x86-64/EIFGENs/classic/F_code/xml_reader ~/.local/bin

type=$1
file_path=$2
file_name=${file_path##*/}


#pushd .

echo
echo Comparing CRC-32 Xpact and eXpat for "$file_name"
echo

echo Type: $type
xml_reader -crc_32 $type -trace -duration 0 $file_path > ~/Desktop/Xpact-$file_name-$type.txt
xml_crc_32 -type $type -trace -duration 0 $file_path > ~/Desktop/eXpat-$file_name-$type.txt


#popd


