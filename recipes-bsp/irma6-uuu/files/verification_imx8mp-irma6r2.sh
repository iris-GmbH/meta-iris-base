#!/bin/sh
source /tmp/hashsums

mmc=$(cat /tmp/mmcdev)

# Calculate hashsums (sha256sum) and compare the results with the value in the hashsum file (grep ..)
# As the partiton is larger than the file content, check only the size of flash.bin (head)
# cut the 2nd part of the output of sha256sum

head -c "$SIZE_FLASHBIN" /dev/mmcblk"${mmc}"boot0 | sha256sum - | cut -d' ' -f1 | grep "$HASH_FLASHBIN" || exit 1
head -c "$SIZE_FLASHBIN" /dev/mmcblk"${mmc}"boot1 | sha256sum - | cut -d' ' -f1 | grep "$HASH_FLASHBIN" || exit 1

mount   /dev/mmcblk${mmc}p2 /mnt/fat || exit 1
sha256sum /mnt/fat/Image | cut -d' ' -f1 | grep "$HASH_KERNEL" || exit 1
sha256sum /mnt/fat/imx8mp-irma6r2.dtb | cut -d' ' -f1 | grep $HASH_DEVTREE || exit 1
umount /mnt/fat
sync

mount   /dev/mmcblk${mmc}p3 /mnt/fat || exit 1
sha256sum /mnt/fat/Image | cut -d' ' -f1 | grep $HASH_KERNEL || exit 1
sha256sum /mnt/fat/imx8mp-irma6r2.dtb | cut -d' ' -f1 | grep $HASH_DEVTREE || exit 1
umount /mnt/fat
sync

head -c "$SIZE_ROOTFS" /dev/mmcblk${mmc}p4 | sha256sum - | cut -d' ' -f1 | grep $HASH_ROOTFS || exit 1
head -c "$SIZE_ROOTFS" /dev/mmcblk${mmc}p6 | sha256sum - | cut -d' ' -f1 | grep $HASH_ROOTFS || exit 1

