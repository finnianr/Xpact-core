
# Find XML files to test Xpact against eXpat

. scripts/install_xml_reader.sh

if [ -e /tmp/xml_reader ]; then
	rm -r /tmp/xml_reader
fi

xml_reader -xml_hunt $* /
