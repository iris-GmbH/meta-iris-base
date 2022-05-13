#!/bin/sh
source /tmp/hashsums

mmc=$(cat /tmp/mmcdev)

# Calculate hashsums (sha256sum) and compare the results with the value in the hashsum file (grep ..)
# As the partiton is larger than the file content, check only the size of flash.bin (head)
# cut the 2nd part of the output of sha256sum

echo "Verify hash of flash.bin on /dev/mmcblk"${mmc}"boot0"
head -c "$SIZE_FLASHBIN" /dev/mmcblk"${mmc}"boot0 | sha256sum - | cut -d' ' -f1 | grep "$HASH_FLASHBIN" || { echo "Error: Failed to verify hash of flash.bin on /dev/mmcblk"${mmc}"boot0"; exit 1; }
echo "Verify hash of flash.bin on /dev/mmcblk"${mmc}"boot1"
head -c "$SIZE_FLASHBIN" /dev/mmcblk"${mmc}"boot1 | sha256sum - | cut -d' ' -f1 | grep "$HASH_FLASHBIN" || { echo "Error: Failed to verify hash of flash.bin on /dev/mmcblk"${mmc}"boot1"; exit 1; }

mount   /dev/mmcblk${mmc}p2 /mnt/fat || exit 1
echo "Verify hash of kernel Image on /dev/mmcblk"${mmc}"p2"
sha256sum /mnt/fat/Image | cut -d' ' -f1 | grep "$HASH_KERNEL" || { echo "Error: Failed to verify hash of kernel Image on /dev/mmcblk"${mmc}"p2"; exit 1; }
echo "Verify hash of *.dtb on /dev/mmcblk"${mmc}"p2"
sha256sum /mnt/fat/imx8mp-irma6r2.dtb | cut -d' ' -f1 | grep $HASH_DEVTREE || { echo "Error: Failed to verify hash of *.dtb on /dev/mmcblk"${mmc}"p2"; exit 1; }
umount /mnt/fat
sync

mount   /dev/mmcblk${mmc}p3 /mnt/fat || exit 1
echo "Verify hash of kernel Image on /dev/mmcblk"${mmc}"p3"
sha256sum /mnt/fat/Image | cut -d' ' -f1 | grep $HASH_KERNEL || { echo "Error: Failed to verify hash of kernel Image on /dev/mmcblk"${mmc}"p3"; exit 1; }
echo "Verify hash of *.dtb on /dev/mmcblk"${mmc}"p3"
sha256sum /mnt/fat/imx8mp-irma6r2.dtb | cut -d' ' -f1 | grep $HASH_DEVTREE || { echo "Error: Failed to verify hash of *.dtb on /dev/mmcblk"${mmc}"p3"; exit 1; }
umount /mnt/fat
sync

echo "Verify hash of rootfs on /dev/mmcblk"${mmc}"p4"
head -c "$SIZE_ROOTFS" /dev/mmcblk${mmc}p4 | sha256sum - | cut -d' ' -f1 | grep $HASH_ROOTFS || { echo "Error: Failed to verify hash of rootfs on /dev/mmcblk"${mmc}"p4"; exit 1; }
echo "Verify hash of rootfs on /dev/mmcblk"${mmc}"p6"
head -c "$SIZE_ROOTFS" /dev/mmcblk${mmc}p6 | sha256sum - | cut -d' ' -f1 | grep $HASH_ROOTFS || { echo "Error: Failed to verify hash of rootfs on /dev/mmcblk"${mmc}"p6"; exit 1; }

