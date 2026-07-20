


path_1=$(ls ~/Desktop/Xpact*.txt)
path_2=$(ls ~/Desktop/eXpat*.txt)

python3 tools/crc_diverge.py $path_1 $path_2

