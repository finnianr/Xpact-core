
# Find XML files to test Xpact against eXpat

. scripts/install_xml_reader.sh

#install_dir=/usr/share
#install_dir=$HOME/.steam
install_dir=$HOME/Documents

extension=$1
echo $install_dir
echo Testing against \*.$extension
xml_reader -test_files "$install_dir/*.$extension"


