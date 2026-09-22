
. scripts/install_xml_reader.sh

echo Generating report benchmark-report-MMM-DD.txt

xml_reader -benchmark_sort benchmarks$1
