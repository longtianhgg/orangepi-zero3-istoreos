#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2013 OpenWrt.org
#
# iStoreOS adaptation:
#   p1 = boot
#   p2 = squashfs rootfs
#   p3 = writable overlay
#

set -ex

[ $# -eq 6 ] || {
    echo "SYNTAX: $0 <file> <bootfs image> <rootfs image> <bootfs size> <rootfs size> <u-boot image>"
    exit 1
}

OUTPUT="$1"
BOOTFS="$2"
ROOTFS="$3"
BOOTFSSIZE="$4"
ROOTFSSIZE_MB="$5"
UBOOT="$6"

# iStoreOS writable overlay partition
USERDATASIZE_MB=2048

head=4
sect=63

set $(ptgen \
    -o "$OUTPUT" \
    -h "$head" \
    -s "$sect" \
    -l 1024 \
    -t c  -p "${BOOTFSSIZE}M" \
    -t 83 -p "${ROOTFSSIZE_MB}M" \
    -t 83 -p "${USERDATASIZE_MB}M")

BOOTOFFSET="$(($1 / 512))"
BOOTSIZE="$(($2 / 512))"

ROOTFSOFFSET="$(($3 / 512))"
ROOTFSSIZE="$(($4 / 512))"

USERDATAOFFSET="$(($5 / 512))"
USERDATASIZE="$(($6 / 512))"

# Ensure the image reaches the end of partition 3.
# truncate creates a sparse zero-filled area efficiently.
truncate -s "$(( (USERDATAOFFSET + USERDATASIZE) * 512 ))" "$OUTPUT"

# U-Boot / SPL
dd bs=1024 if="$UBOOT" of="$OUTPUT" seek=8 conv=notrunc

# FAT boot partition
dd bs=512 if="$BOOTFS" of="$OUTPUT" \
    seek="$BOOTOFFSET" conv=notrunc

# SquashFS root filesystem
dd bs=512 if="$ROOTFS" of="$OUTPUT" \
    seek="$ROOTFSOFFSET" conv=notrunc

# iStoreOS mount_root recognises RESET and formats p3 as ext4
echo "RESET000" | dd of="$OUTPUT" \
    bs=512 seek="$USERDATAOFFSET" conv=notrunc,sync count=1

