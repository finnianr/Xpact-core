
# Find XML files to test Xpact against eXpat

. scripts/install_xml_reader.sh

mount_dir=/media/Windows
dev_ntfs=/dev/nvme0n1p3

if [ -d "$mount_dir" ]; then
	echo Unmount first in file explorer
	return
fi

sudo mkdir $mount_dir

# WARNING: ntfs3 is black-listed driver
# Mount in readonly mode using safe args

sudo modprobe ntfs3
sudo mount -t ntfs3 $dev_ntfs $mount_dir -o ro,noatime,uid=$(id -u),gid=$(id -g)

xml_reader -xml_hunt $* $mount_dir

sudo umount $mount_dir

sudo rmdir $mount_dir

sudo modprobe -r ntfs3
