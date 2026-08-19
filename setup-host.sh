#!/usr/bin/env bash
set -euo pipefail

QEMU_STATIC=/usr/bin/qemu-aarch64-static

if [ ! -f "${QEMU_STATIC}" ]; then
    echo "ERROR: ${QEMU_STATIC} not found. Install qemu-user-static first." 1>&2
    exit 1
fi

echo ':qemu-aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:'"${QEMU_STATIC}"':F' > /proc/sys/fs/binfmt_misc/register

echo "Registered ${QEMU_STATIC} for arm64 emulation."
echo "This registration is not persistent. Run this script again after a reboot."
