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
echo "Verify hash of fitimage on /dev/mmcblk"${mmc}"p2"
sha256sum /mnt/fat/fitImage.signed | cut -d' ' -f1 | grep "$HASH_FITIMAGE" || { echo "Error: Failed to verify hash of fitimage on /dev/mmcblk"${mmc}"p2"; exit 1; }
umount /mnt/fat
sync

mount   /dev/mmcblk${mmc}p3 /mnt/fat || exit 1
echo "Verify hash of fitimage on /dev/mmcblk"${mmc}"p3"
sha256sum /mnt/fat/fitImage.signed | cut -d' ' -f1 | grep $HASH_FITIMAGE || { echo "Error: Failed to verify hash of fitimage on /dev/mmcblk"${mmc}"p3"; exit 1; }
umount /mnt/fat
sync

mkdir -p /mnt/keystore
mount -t vfat /dev/mapper/irma6lvm-keystore /mnt/keystore
echo "Verify hash of rootfs on /dev/mapper/decrypted-irma6lvm-rootfs_a"
head -c "$SIZE_ROOTFS" /dev/mapper/decrypted-irma6lvm-rootfs_a | sha256sum - | cut -d' ' -f1 | grep $HASH_ROOTFS || { echo "Error: Failed to verify hash of rootfs on /dev/mapper/decrypted-irma6lvm-rootfs_a"; exit 1; }
veritysetup verify /dev/mapper/decrypted-irma6lvm-rootfs_a /dev/mapper/irma6lvm-rootfs_a_hash $(cat /mnt/keystore/rootfs_a_roothash) || { echo "Error: dm-verity verification fail on /dev/mapper/decrypted-irma6lvm-rootfs_a"; exit 1; }
echo "Verify hash of rootfs on /dev/mapper/decrypted-irma6lvm-rootfs_b"
head -c "$SIZE_ROOTFS" /dev/mapper/decrypted-irma6lvm-rootfs_b | sha256sum - | cut -d' ' -f1 | grep $HASH_ROOTFS || { echo "Error: Failed to verify hash of rootfs on /dev/mapper/decrypted-irma6lvm-rootfs_b"; exit 1; }
veritysetup verify /dev/mapper/decrypted-irma6lvm-rootfs_b /dev/mapper/irma6lvm-rootfs_b_hash $(cat /mnt/keystore/rootfs_b_roothash) || { echo "Error: dm-verity verification fail on /dev/mapper/decrypted-irma6lvm-rootfs_b"; exit 1; }
umount /mnt/keystore
