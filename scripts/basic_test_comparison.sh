
# Basic XML files to test Xpact against eXpat including attack files

clear
echo Installing xml_reader
cp -u examples/build/linux-x86-64/EIFGENs/classic/F_code/xml_reader ~/.local/bin

echo Testing against \*.svg

xml_reader -test_files examples/data
echo

xml_reader -test_files "$HOME/Dev/C/libexpat/testdata/largefiles/*.xml"

