
# Find XML files to test Xpact against eXpat

clear
echo Installing xml_reader
cp -u examples/build/linux-x86-64/EIFGENs/classic/F_code/xml_reader ~/.local/bin

pushd .


cd /usr/share/icons

echo Testing against \*.svg

xml_reader -test_files *.svg


popd
