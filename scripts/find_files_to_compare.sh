
# Find XML files to test Xpact against eXpat

clear
echo Installing xml_reader
cp -u examples/build/linux-x86-64/EIFGENs/classic/F_code/xml_reader ~/.local/bin

echo ui file count\: 220 passed


echo Testing against \*.xml
xml_reader -test_files -log docs/test-logs/xml-ui.log "/usr/share/*.xml"

