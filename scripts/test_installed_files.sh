
# Find XML files to test Xpact against eXpat

. scripts/install_xml_reader.sh

#install_dir=/usr/share
#install_dir=$HOME/.steam
#install_dir=$HOME/Documents
#install_dir=/media/finnian/Windows1/Windows/System32
install_dir=/media/finnian/Windows1/Windows/servicing/Packages
#install_dir=$ISE_EIFFEL

extension=$1
echo $install_dir
echo Testing against \*.$extension
xml_reader -test_files -keep_logs "$install_dir/*.$extension"


