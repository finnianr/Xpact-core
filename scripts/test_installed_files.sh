
# Find XML files to test Xpact against eXpat

. scripts/install_xml_reader.sh

#install_dir=/usr/share
#install_dir=$HOME/.steam
#install_dir=$HOME/Documents
#install_dir=$ISE_EIFFEL
#install_dir=/media/finnian/Windows/Windows/System32
#install_dir=/media/finnian/Windows/Windows/servicing/Packages
#install_dir="/media/finnian/Windows/Program Files/WindowsApps"
#install_dir=/media/finnian/Windows/ProgramData/Microsoft/Windows/AppRepository
#install_dir="/media/finnian/Windows/Program Files/WindowsApps"
#install_dir=/media/finnian/Windows/Users/Finnian/AppData/Local/Packages
#install_dir=/media/finnian/Windows/Windows/System32/config/systemprofile/AppData

install_dir=/media/finnian/Windows/Users/Finnian/AppData

if [ ! -d "$install_dir" ]; then
	echo Directory not found\: $install_dir
fi

extension=$1
echo $install_dir
echo Testing against \*.$extension
xml_reader -test_files -keep_logs "$install_dir/*.$extension"

