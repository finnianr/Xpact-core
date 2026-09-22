
# Mount Windows partition with LABEL=Windows as /media/Windows using ntfs3 module
# and then scan for XML files to test Xpact against eXpat

. scripts/install_xml_reader.sh

mount_dir=/media/Windows

if [ -d "$mount_dir" ]; then
	echo Unmount first in file explorer
	return
fi

sudo mkdir $mount_dir

# WARNING: ntfs3 is black-listed driver
# Mount in readonly mode using safe args

sudo modprobe ntfs3
sudo mount -t ntfs3 LABEL=Windows $mount_dir -o ro,noatime,uid=$(id -u),gid=$(id -g)

if [ $? -ne 0 ]; then
	echo "Failed to mount Windows partition"
	sudo rmdir $mount_dir
	return
fi

if [ -e /tmp/xml_reader ]; then
	rm -r /tmp/xml_reader
fi

xml_reader -xml_hunt $* $mount_dir
# /Windows/WinSxS

sudo umount $mount_dir

sudo rmdir $mount_dir

sudo modprobe -r ntfs3
